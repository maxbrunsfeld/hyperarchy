//= require spec/spec_helper

describe("Views.Pages.Election.CandidateDetails", function() {
  var candidateDetails, candidate, creator, election;

  beforeEach(function() {
    renderLayout();
    Application.height(1000);
    
    candidateDetails = Application.electionPage.candidateDetails;
    creator = User.createFromRemote({id: 999, emailHash: 'blas', firstName: "Mr.", lastName: "Creator"});
    Application.currentUser(creator);
    var organization = Organization.createFromRemote({id: 42});
    election = organization.elections().createFromRemote({id: 1, creatorId: 999, createdAt: 12});
    candidate = creator.candidates().createFromRemote({id: 1, electionId: 1, body: "Mustard.", details: "Pardon me. Do you have any Gray Poupon?", createdAt: 1308352736162});

    Application.electionPage.show();
    Application.electionPage.showCandidateDetails();

    candidateDetails.candidate(candidate);
  });

  describe("when the candidate is assigned", function() {
    it("populates the body, details, and avatar", function() {
      expect(candidateDetails.body.text()).toEqual(candidate.body());
      expect(candidateDetails.details.text()).toEqual(candidate.details());
      candidate.remotelyUpdated({body: "Catsup", details: "37 flavors"});
      expect(candidateDetails.body.text()).toEqual(candidate.body());
      expect(candidateDetails.details.text()).toEqual(candidate.details());
      expect(candidateDetails.avatar.user()).toBe(candidate.creator());
      expect(candidateDetails.creatorName.text()).toBe(creator.fullName());
      expect(candidateDetails.createdAt.text()).toBe(candidate.formattedCreatedAt());
    });

    it("removes subscriptions to the previous candidate", function() {
      var candidate2 = Candidate.createFromRemote({id: 57, body: "soup.", electionId: election.id(), createdAt: 1111, creatorId: creator.id()});
      var subscriptionsBefore = candidate.onDestroyNode.size();

      candidateDetails.candidate(candidate2);

      expect(candidate.onDestroyNode.size()).toBe(subscriptionsBefore - 1);

      spyOn(History, 'pushState');
      candidate.remotelyDestroyed();
      expect(History.pushState).not.toHaveBeenCalled();
    });

    it("hides the form if it is showing, even if the candidate does not change", function() {
      candidateDetails.candidate(candidate);

      candidateDetails.editButton.click();

      expect(candidateDetails.form).toBeVisible();
      expect(candidateDetails.nonEditableContent).toBeHidden();

      candidateDetails.candidate(candidate);

      expect(candidateDetails.form).toBeHidden();
      expect(candidateDetails.nonEditableContent).toBeVisible();
    });

    it("handles null candidates", function() {
      candidateDetails.candidate(null);
    });
  });

  describe("showing and hiding of the edit and destroy buttons", function() {
    var currentUserCanEdit;
    beforeEach(function() {
      spyOn(Candidate.prototype, 'editableByCurrentUser').andCallFake(function() {
        return currentUserCanEdit;
      });
    });

    describe("on candidate assignment", function() {
      it("shows the edit link only if the current user can edit", function() {
        var otherCandidate = Candidate.createFromRemote({id: 100, creatorId: creator.id(), createdAt: 234234});

        currentUserCanEdit = false;
        candidateDetails.candidate(otherCandidate);
        expect(candidateDetails).not.toHaveClass('mutable');
        expect(candidateDetails.editButton).toBeHidden();
        expect(candidateDetails.destroyButton).toBeHidden();


        currentUserCanEdit = true;
        candidateDetails.candidate(candidate);
        expect(candidateDetails).toHaveClass('mutable');
        expect(candidateDetails.editButton).toBeVisible();
        expect(candidateDetails.destroyButton).toBeVisible();
      });
    });

    describe("on user switch", function() {
      it("shows the edit button only when the current user is the creator of the candidate, an owner of the organization, or an admin", function() {
        var otherUser = User.createFromRemote({id: 123});

        currentUserCanEdit = false;
        Application.currentUser(otherUser);
        expect(candidateDetails.editButton).toBeHidden();
        expect(candidateDetails.destroyButton).toBeHidden();

        currentUserCanEdit = true;
        Application.currentUser(creator);
        expect(candidateDetails.editButton).toBeVisible();
        expect(candidateDetails.destroyButton).toBeVisible();
      });
    });
  });

  describe("showing and hiding the new form", function() {
    it("hides comments and empties out and shows the form fields & create button when #showNewForm is called", function() {
      candidateDetails.editableBody.val("woweee!");
      candidateDetails.editableDetails.val("cocooo!");
      candidateDetails.cancelEdit();

      var now = new Date();
      spyOn(window, 'Date').andReturn(now);

      expect(candidateDetails.createButton).toBeHidden();
      candidateDetails.showNewForm();
      expect(candidateDetails.form).toBeVisible();
      expect(candidateDetails.editableBody.val()).toBe('');
      expect(candidateDetails.editableDetails.val()).toBe('');
      expect(candidateDetails.createButton).toBeVisible();
      expect(candidateDetails.canceleditButton).toBeHidden();
      expect(candidateDetails.updateButton).toBeHidden();
      expect(candidateDetails.comments).toBeHidden();

      expect(candidateDetails.avatar.user()).toBe(Application.currentUser());
      expect(candidateDetails.creatorName.text()).toBe(Application.currentUser().fullName());
      expect(candidateDetails.createdAt.text()).toBe($.PHPDate("M j, Y @ g:ia", now));

      candidateDetails.candidate(candidate);

      expect(candidateDetails.form).toBeHidden();
      expect(candidateDetails.createButton).toBeHidden();
      expect(candidateDetails.canceleditButton).toBeHidden();
      expect(candidateDetails.updateButton).toBeHidden();
      expect(candidateDetails.comments).toBeVisible();
    });
  });

  describe("when the create button is clicked", function() {
    var fieldValues;

    beforeEach(function() {
      useFakeServer();
      Application.electionPage.election(election);
      candidateDetails.showNewForm();
      fieldValues = {
        body: "Relish",
        details: "That green stuff..."
      };

      candidateDetails.editableBody.val(fieldValues.body);
      candidateDetails.editableDetails.val(fieldValues.details);
    });

    describe("when the current user is a member", function() {
      describe("when the body field is filled in", function() {
        it("creates a new candidates with the given body and details on the server and hides the form", function() {
          candidateDetails.createButton.click();

          expect(Server.creates.length).toBe(1);

          expect(Server.lastCreate.record.dirtyWireRepresentation()).toEqual(_.extend(fieldValues, {election_id: election.id()}));
          Server.lastCreate.simulateSuccess();

          expect(Path.routes.current).toBe(election.url());
        });

        it("wires the form submit event to save", function() {
          candidateDetails.form.submit();
          expect(Server.updates.length).toBe(1);
        });
      });

      describe("when the body field is empty", function() {
        it("does nothing", function() {
          spyOn(History, 'pushState');
          candidateDetails.editableBody.val('                  ');
          candidateDetails.createButton.click();
          expect(Server.creates.length).toBe(0);
          expect(History.pushState).not.toHaveBeenCalled();
        });
      });
    });

    describe("when the current user is a guest", function() {
      var guest, member;

      beforeEach(function() {
        spyOn(candidate, 'editableByCurrentUser').andReturn(true);
        guest = User.createFromRemote({id: 5, guest: true});
        member = User.createFromRemote({id: 6});
        Application.currentUser(guest);


        candidateDetails.show();
        candidateDetails.showNewForm();
        candidateDetails.editableBody.val(fieldValues.body);
        candidateDetails.editableDetails.val(fieldValues.details);
      });

      it("prompts for signup, and creates a candidate only if they sign up", function() {
        candidateDetails.createButton.click();

        expect(Server.creates.length).toBe(0);
        expect(Application.signupForm).toBeVisible();
        Application.signupForm.firstName.val("Dude");
        Application.signupForm.lastName.val("Richardson");
        Application.signupForm.emailAddress.val("dude@example.com");
        Application.signupForm.password.val("wicked");
        Application.signupForm.form.submit();
        expect($.ajax).toHaveBeenCalled();

        $.ajax.mostRecentCall.args[0].success({ current_user_id: member.id() });

        expect(Server.creates.length).toBe(1);

        var createdCandidate = Server.lastCreate.record;

        expect(createdCandidate.election()).toBe(election);
        expect(createdCandidate.body()).toBe(fieldValues.body);
        expect(createdCandidate.details()).toBe(fieldValues.details);

        Server.lastCreate.simulateSuccess();

        expect(Path.routes.current).toBe(election.url());
      });
    });
  });
  
  describe("handling of the enter key on the body textarea", function() {
    beforeEach(function() {
      useFakeServer();
      Application.electionPage.election(election);
    });

    it("creates the candidate when the new form is showing", function() {
      candidateDetails.showNewForm();
      candidateDetails.editableBody.val("Blah");
      candidateDetails.editableBody.trigger({ type : 'keydown', which : 13 });
      expect(Server.creates.length).toBe(1);
    });

    it("updates the candidate when the edit form is showing", function() {
      candidateDetails.editButton.click();
      candidateDetails.editableBody.val("Blah");
      candidateDetails.editableBody.trigger({ type : 'keydown', which : 13 });
      expect(Server.updates.length).toBe(1);
    });
  });

  describe("showing and hiding of the edit form", function() {
    it("shows and populates the form fields and sets focus when edit is clicked and hides them when cancel is clicked", function() {
      expect(candidateDetails.form).toBeHidden();
      expect(candidateDetails.nonEditableContent).toBeVisible();

      candidateDetails.editButton.click();

      expect(candidateDetails.form).toBeVisible();
      expect(candidateDetails.updateButton).toBeVisible();
      expect(candidateDetails.canceleditButton).toBeVisible();
      expect(candidateDetails.nonEditableContent).toBeHidden();

      expect(candidateDetails.editableBody.val()).toBe(candidate.body());
      expect(candidateDetails.editableBody[0]).toBe(document.activeElement);
      expect(candidateDetails.charsRemaining.text()).toBe((140 - candidate.body().length).toString());
      expect(candidateDetails.editableDetails.val()).toBe(candidate.details());

      candidateDetails.canceleditButton.click();

      expect(candidateDetails.form).toBeHidden();
      expect(candidateDetails.updateButton).toBeHidden();
      expect(candidateDetails.canceleditButton).toBeHidden();
      expect(candidateDetails.nonEditableContent).toBeVisible();
    });
  });

  describe("when the update button is clicked", function() {
    var fieldValues;

    beforeEach(function() {
      useFakeServer();
      candidateDetails.editButton.click();
      fieldValues = {
        body: "Relish",
        details: "That green stuff..."
      }

      candidateDetails.editableBody.val(fieldValues.body);
      candidateDetails.editableDetails.val(fieldValues.details);
    });

    it("updates the record's body and details on the server and hides the form", function() {
      candidateDetails.updateButton.click();
  
      expect(Server.updates.length).toBe(1);

      expect(Server.lastUpdate.dirtyFieldValues).toEqual(fieldValues);
      Server.lastUpdate.simulateSuccess();

      expect(candidateDetails.form).toBeHidden();
      expect(candidateDetails.nonEditableContent).toBeVisible();
      
      expect(candidateDetails.body.text()).toBe(fieldValues.body);
      expect(candidateDetails.details.text()).toBe(fieldValues.details);
    });

    it("wires the form submit event to save", function() {
      candidateDetails.form.submit();
      expect(Server.updates.length).toBe(1);
    });

    it("does not allow a blank body", function() {
      spyOn(History, 'pushState');
      candidateDetails.editableBody.val('  ');
      candidateDetails.updateButton.click();
      expect(Server.updates.length).toBe(0);
      expect(History.pushState).not.toHaveBeenCalled();
    });

    it("does not allow a body exceeding 140 chars", function() {
      var longBody = ""
      _.times(141, function() {
        longBody += "X"
      });

      spyOn(History, 'pushState');
      candidateDetails.editableBody.val(longBody);
      candidateDetails.updateButton.click();
      expect(Server.updates.length).toBe(0);
      expect(History.pushState).not.toHaveBeenCalled();
    });
  });

  describe("when the destroy button is clicked", function() {
    beforeEach(function() {
      useFakeServer();
    });

    describe("if the user accepts the confirmation", function() {
      it("deletes the candidate", function() {
        spyOn(window, 'confirm').andReturn(true);

        candidateDetails.destroyButton.click();

        expect(Server.destroys.length).toBe(1);
        expect(Server.lastDestroy.record).toBe(candidate);
      });
    });

    describe("if the user rejects the confirmation", function() {
      it("does not delete the candidate", function() {
        spyOn(window, 'confirm').andReturn(false);

        candidateDetails.destroyButton.click();

        expect(Server.destroys.length).toBe(0);
      });
    });
  });

  describe("when the candidate is destroyed", function() {
    it("navigates to the election url", function() {
      candidate.remotelyDestroyed();
      expect(Path.routes.current).toBe(election.url());
    });
  });
  
  describe("adjustment of the comments height", function() {
    var longText;

    beforeEach(function() {
      longText = "";
      for (var i = 0; i < 10; i++) longText += "Bee bee boo boo ";
      spyOn(candidateDetails.comments, 'enableOrDisableFullHeight');
    });

    describe("when the details/body are assigned and when they change", function() {
      it("adjusts the comments to fill the remaining available height", function() {
        Application.electionPage.showCandidateDetails();
        expectCommentsToHaveFullHeight();

        candidate.remotelyUpdated({body: longText});
        expectCommentsToHaveFullHeight();

        candidate.remotelyUpdated({details: longText});
        expectCommentsToHaveFullHeight();
        expect(candidateDetails.comments.enableOrDisableFullHeight).toHaveBeenCalled();
      });
    });

    describe("when the form is shown and hidden", function() {
      it("adjusts the comments to fill the remaining available height", function() {
        candidateDetails.editButton.click();
        expectCommentsToHaveFullHeight();
        
        candidateDetails.canceleditButton.click();
        expectCommentsToHaveFullHeight();
        expect(candidateDetails.comments.enableOrDisableFullHeight).toHaveBeenCalled();
      });
    });

    describe("when the window is resized", function() {
      it("adjusts the comments to fill the remaining available height", function() {
        Application.electionPage.width(1200);
        candidate.remotelyUpdated({details: longText});

        Application.electionPage.width(800);
        $(window).resize();
        expectCommentsToHaveFullHeight();
        expect(candidateDetails.comments.enableOrDisableFullHeight).toHaveBeenCalled();
      });
    });

    describe("when the body or details textareas resize elastically", function() {
      it("adjusts the comments to fill the remaining available height", function() {
        candidateDetails.editButton.click();

        candidateDetails.editableBody.val(longText);
        candidateDetails.editableBody.keyup();
        expectCommentsToHaveFullHeight();

        candidateDetails.editableDetails.val(longText);
        candidateDetails.editableDetails.keyup();

        expectCommentsToHaveFullHeight();
        expect(candidateDetails.comments.enableOrDisableFullHeight).toHaveBeenCalled();
      });
    });

    function expectCommentsToHaveFullHeight() {
      var commentsBottom = candidateDetails.comments.position().top + candidateDetails.comments.outerHeight();
      expect(commentsBottom).toBe(candidateDetails.outerHeight() - parseInt(candidateDetails.css('padding-bottom')));
    }
  });

  describe("when the close link is clicked", function() {
    beforeEach(function() {
      Application.electionPage.election(election);
    });

    describe("when the view is in 'new' mode", function() {
      it("routes to the election's url", function() {
        Application.electionPage.election(election);
        candidateDetails.candidate(null);
        candidateDetails.showNewForm();
        spyOn(Application, 'showPage');
        candidateDetails.closeLink.click();
        expect(Path.routes.current).toBe(election.url());
      });
    });

    describe("when the view is in 'details' mode", function() {
      it("routes to the election's url", function() {
        spyOn(Application, 'showPage');
        candidateDetails.closeLink.click();
        expect(Path.routes.current).toBe(election.url());
      });
    });
  });
});
