require File.expand_path("#{File.dirname(__FILE__)}/../../eden_spec_helper")

module Http
  describe StaticAssetManager do
    attr_reader :dir
    before do
      @dir = File.dirname(__FILE__)
    end

    before do
      StaticAssetManager.add_js_directory("#{dir}/public_dir_spec/exposed_public_dir_1", "/virtual_dir_1")
      StaticAssetManager.add_js_directory("#{dir}/public_dir_spec/external_public_dir_2", "/virtual_dir_2")
    end

    describe "#relative_paths_of_dependencies" do
      it "computes the relative paths of all dependencies of the given javascript paths, accounting for virtual subdirectories" do
        expected_relative_paths = [
          "/virtual_dir_1/duplicated_dependency.js",
          "/virtual_dir_1/dependency_1.js",
          "/virtual_dir_1/exposed_public_subdir/dependency_3.js",
          "/virtual_dir_1/top_level_1.js",
          "/virtual_dir_1/top_level_2.js"
        ]
        StaticAssetManager.relative_paths_of_dependencies('top_level_1.js', 'top_level_2.js').should == expected_relative_paths
      end
    end

    describe "#call" do
      context "when the given path corresponds to a registered virtual prefix" do
        context "when a file exists at the corresponding physical location" do
          it "returns the contents of the file at the physical location" do
            request = TestRequest.new
            request.path_info = "/virtual_dir_1/dependency_1.js"
            StaticAssetManager.call(request.env).should == [
              200,
              {"Last-Modified"=>"Tue, 01 Sep 2009 00:40:24 GMT", "Content-Type"=>"application/javascript", "Content-Length"=>18},
              "var dependency_1;\n"
            ]
          end
        end

        context "when no file exists at the corresponding physical location" do
          it "proxies the request through to #proxied_app" do

          end
        end
      end

      context "when the given path does not correspond to a registered virtual prefix" do
        it "proxies the request through to #proxied_app" do

        end
      end
    end
  end
end
