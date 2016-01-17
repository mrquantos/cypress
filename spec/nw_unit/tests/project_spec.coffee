lookup       = require("../js/spec_helper")
cache        = lookup("lib/cache")

module.exports = (parentWindow, gui, loadApp) ->
  ## Project must be the very first test because
  ## we load up everything in node at that time
  ## and it crashes if its the 2nd window to open
  describe "Projects", ->
    beforeEach ->
      Fixtures.scaffold()

      @todos = Fixtures.project("todos")

      cache.setUser({name: "Brian", session_token: "abc123"}).then =>
        cache.addProject(@todos).then =>
          loadApp(@)

    afterEach ->
      Fixtures.remove()

    # context "starting the server", ->
    #   it "displays loading indicator", ->
    #     project = @$("#projects-container .project")
    #     project.click()

    #     loading = @$("i.fa.fa-spinner.fa-spin")
    #     expect(loading).to.exist

    #     span = @$("#project span")
    #     expect(span).to.contain("Starting Server...")

    context "server started", ->
      beforeEach ->
        @trigger = @sandbox.spy(@App.vent, "trigger")
        @$("#projects-container .project").click()

        Promise.delay(1500).then =>
          @project = @$("#project")

      afterEach ->
        @project.find("[data-stop]").click()

        ## it should stop and go back to the projects view
        Promise.delay(500).then =>
          expect(@$("project")).not.to.exist
        .delay(1000)

      it "calls project:clicked with options + displays project information", ->
        expect(@trigger).to.be.calledWith("project:clicked")
        expect(@trigger.getCall(0).args[2]).to.be.an("object")
        expect(@trigger.getCall(0).args[2]).to.have.property("projectPath")

        expect(@project.find("h3")).to.contain("todos")
        expect(@project.find(".well")).to.contain("Server Running")
        expect(@project.find("a")).to.contain("http://localhost:8888")
        expect(@project.find("button[data-stop]")).to.contain("Stop")

        fs.readJsonAsync(@todos + "/cypress.json").then (json) =>
          json.port = 8887

          fs.writeJsonAsync(@todos + "/cypress.json", json).then =>
            Promise.delay(500).then =>
              expect(@$("#project").find("a")).to.contain("http://localhost:8887")

    context "boot errors", ->
      it "cypress.json parse errors", ->
        fs.writeFileSync @todos + "/cypress.json", "{'foo': 'bar}"
        @$("#projects-container .project").click()

        Promise.delay(1000).then =>
          project = @$("#project")
          expect(project.find("p.text-danger")).to.contain("Could not start server!")
          expect(project.find("p.bg-danger")).to.contain("Error reading from")
          expect(project.find("p.bg-danger")).to.contain("Unexpected token")
          expect(project.find("p.bg-danger br")).to.have.length(2)

      it "cypress.env.json parse errors", ->
        fs.writeFileSync @todos + "/cypress.env.json", "{'foo': 'bar}"
        @$("#projects-container .project").click()

        Promise.delay(1000).then =>
          project = @$("#project")
          expect(project.find("p.text-danger")).to.contain("Could not start server!")
          expect(project.find("p.bg-danger")).to.contain("Error reading from")
          expect(project.find("p.bg-danger")).to.contain("Unexpected token")
          expect(project.find("p.bg-danger br")).to.have.length(2)

      it "permission problems adding project", ->
        @permissions = Fixtures.project("permissions")

        ## remove read permissions
        fs.chmodSync(@permissions, "111")

        ## trigger a project being added
        App.mainRegion.currentView.trigger("project:added", @permissions)

        Promise.delay(500).then =>
          projects = @$("#projects")

          expect(projects.find("header")).not.to.exist
          expect(projects.find("h3")).to.contain("Error adding project!")
          expect(projects.find("p")).to.contain("Error writing to:")
          expect(projects.find("p")).to.contain(@permissions)
          expect(projects.find("p")).to.contain("EACCES")

          projects.find("button").click()

          Promise.delay(500).then =>
            projects = @$("#projects")
            expect(projects.find("header")).to.exist
            expect(projects.find(".project")).to.exist

    context "projects list", ->
      it "displays added project", ->
        project = @$("#projects-container .project")
        expect(project).to.have.length(1)

        expect(project.find("h4")).to.contain("todos")
        expect(project.find("small")).to.contain(@todos)
