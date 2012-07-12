
describe("right menu", function() {
  var view;
  beforeEach(function() {
    cdb.templates.add(new cdb.core.Template({
      name: 'table/views/right_panel',
      compiled: _.template(
      '<section class="table_panel">' + 
        '<div class="sidebar">' + 
          '<nav class="tools">' + 
          '</nav>' +
          '<nav class="edit">' +
          '</nav>' +
        '</div>' + 
        '<div class="views">' +
        '</div>' +
      '</section>'
      )
    }));
    view = new cdb.admin.RightMenu();
  });

  it("should render", function() {
    var el = view.render().$el;
    expect(el.find('.sidebar')).toBeTruthy();
    expect(el.find('.views')).toBeTruthy();
  });

  it("should add view and a button", function() {
    var v = new cdb.core.View();
    v.buttonClass = 'testButtonClass';
    v.type = 'tool';
    view.render();
    view.addModule(v);
    expect(view.$el.find('.views').children().length).toEqual(1);
    expect(view.$el.find('.tools').children().length).toEqual(1);
  });
  it("should activate right panel", function() {
    var v = new cdb.core.View();
    v.buttonClass = 'testButtonClass';
    v.type = 'tool';
    view.render();
    view.addModule(v);

    var v2 = new cdb.core.View();
    v2.buttonClass = 'testButtonClass2';
    v2.type = 'tool';
    view.addModule(v2);

    expect(view.panels.activeTab).toEqual('testButtonClass2');

    view.$('.sidebar .testButtonClass').trigger('click');

    expect(view.panels.activeTab).toEqual('testButtonClass');

  });
});
