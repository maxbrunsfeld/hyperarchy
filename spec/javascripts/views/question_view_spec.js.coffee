{ User, Question, Answer, Ranking } = Models
{ Server } = Monarch.Remote

describe "Views.QuestionView", ->
  [currentUser, question, answer1, answer2, answer3, questionView] = []

  beforeEach ->
    currentUser = User.created(id: 1, fullName: "Current User")
    User.currentUserId = currentUser.id()
    question = Question.created(id: 1, body: "What's your favorite color?", creatorId: currentUser.id())
    answer1 = question.answers().created(id: 1, body: "Red", position: 1)
    answer2 = question.answers().created(id: 2, body: "Green", position: 2)
    answer3 = question.answers().created(id: 3, body: "Blue", position: 3)

    spyOn(Ranking, 'createOrUpdate').andCallFake -> $.Deferred().promise()
    spyOn(Ranking, 'destroyByAnswerId').andCallFake -> $.Deferred().promise()
    spyOn($.fn, 'effect') # animations break in spec environment, so disable them

  afterEach ->
    questionView?.remove()

  describe "when initally rendered", ->
    it "populates itself with current rankings", ->
      currentUser.rankings().created(id: 1, answerId: 1, questionId: 1, position: .5)
      currentUser.rankings().created(id: 2, answerId: 2, questionId: 1, position: 2)

      questionView = new Views.QuestionView(question)
      items = questionView.personalVote.find('.answer')
      expect(items.length).toBe 2

      expect(items.eq(0).text()).toBe answer2.body()
      expect(items.eq(0).data('position')).toBe 2
      expect(items.eq(1).text()).toBe answer1.body()
      expect(items.eq(1).data('position')).toBe .5

      item1 = questionView.collectiveVote.find('[data-answer-id=1]').clone()
      questionView.personalVote.append(item1)
      questionView.updateAnswerRanking(item1)
      expect(questionView.personalVote.find('.answer').length).toBe 2

    it "only shows the edit / delete buttons if the current user created the question", ->
      questionView = new Views.QuestionView(question)
      $('#test-content').append(questionView)
      expect(questionView.deleteButton).toBeVisible()
      expect(questionView.editButton).toBeVisible()
      questionView.remove()

      otherUser = User.created(id: 2)
      User.currentUserId = 2
      questionView = new Views.QuestionView(question)
      $('#test-content').append(questionView)
      expect(questionView.deleteButton).toBeHidden()
      expect(questionView.editButton).toBeHidden()

  describe "when items are dragged into / within the personal ranking list", ->
    it "creates / updates a ranking for the dragged answer", ->
      questionView = new Views.QuestionView(question)

      item1 = questionView.collectiveVote.find('[data-answer-id=1]').clone()
      item2 = questionView.collectiveVote.find('[data-answer-id=2]').clone()
      item3 = questionView.collectiveVote.find('[data-answer-id=3]').clone()

      # drag/drop first item
      questionView.personalVote.append(item1)
      questionView.updateAnswerRanking(item1)

      expect(Ranking.createOrUpdate).toHaveBeenCalled()
      expect(Ranking.createOrUpdate.argsForCall[0][0].answer.id()).toBe 1
      expect(Ranking.createOrUpdate.argsForCall[0][0].position).toBe 1
      Ranking.createOrUpdate.reset()

      # drag/drop next item
      questionView.personalVote.prepend(item2)
      questionView.updateAnswerRanking(item2)
      expect(Ranking.createOrUpdate).toHaveBeenCalled()
      expect(Ranking.createOrUpdate.argsForCall[0][0].answer.id()).toBe 2
      expect(Ranking.createOrUpdate.argsForCall[0][0].position).toBe 2
      Ranking.createOrUpdate.reset()

      # simulate the rankings completing on the server, out of order
      ranking2 = Ranking.created(id: 2, userId: currentUser.id(), answerId: 2, position: 2)
      ranking1 = Ranking.created(id: 1, userId: currentUser.id(), answerId: 1, position: 1)
      expect(questionView.personalVote.find('.answer').length).toBe 2

      # drag/drop next item between the first two
      questionView.personalVote.find('.answer:first').after(item3)
      questionView.updateAnswerRanking(item3)
      expect(Ranking.createOrUpdate).toHaveBeenCalled()
      expect(Ranking.createOrUpdate.argsForCall[0][0].answer.id()).toBe 3
      expect(Ranking.createOrUpdate.argsForCall[0][0].position).toBe 1.5
      Ranking.createOrUpdate.reset()
      ranking3 = Ranking.created(id: 3, userId: currentUser.id(), answerId: 3, position: 1.5)

      # move item1 from bottom to the middle
      item1 = questionView.personalVote.find('.answer[data-answer-id=1]')
      questionView.personalVote.find('.answer:first').after(item1.detach())
      questionView.updateAnswerRanking(item1)
      expect(Ranking.createOrUpdate).toHaveBeenCalled()
      expect(Ranking.createOrUpdate.argsForCall[0][0].answer.id()).toBe 1
      expect(Ranking.createOrUpdate.argsForCall[0][0].position).toBe 1.75
      Ranking.createOrUpdate.reset()

      # drag another clone of item1 from collective ranking: it should not duplicate
      item1b = questionView.collectiveVote.find('[data-answer-id=1]').clone()
      questionView.personalVote.append(item1b)
      questionView.updateAnswerRanking(item1b)
      expect(questionView.personalVote.find('.answer').length).toBe 3
      expect(questionView.personalVote.find('.answer:last').data('answer-id')).toBe 1
      expect(Ranking.createOrUpdate).toHaveBeenCalled()
      expect(Ranking.createOrUpdate.argsForCall[0][0].answer.id()).toBe 1
      expect(Ranking.createOrUpdate.argsForCall[0][0].position).toBe .75

      # even when the operation completes on server, no duplication
      ranking1.updated(position: .75)
      expect(questionView.personalVote.find('.answer').length).toBe 3

  describe "when items are dragged out of the list", ->
    it "destroys the ranking for the dragged answer", ->
      currentUser.rankings().created(id: 1, answerId: 1, questionId: 1, position: .5)
      currentUser.rankings().created(id: 2, answerId: 2, questionId: 1, position: 2)
      questionView = new Views.QuestionView(question)

      item = questionView.personalVote.find('.answer[data-answer-id=2]')
      item.detach()
      questionView.updateAnswerRanking(item)

      expect(Ranking.destroyByAnswerId).toHaveBeenCalledWith(2)
