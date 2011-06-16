require 'wx'
include Wx

class KriekFrame < Frame
  def initialize
    super(nil, 01, 'Kriek')
    @kriek_panel = Panel.new(self)
    @jira_label = StaticText.new(@kriek_panel, -1, 'Jira:  KITT-', DEFAULT_POSITION, DEFAULT_SIZE)
    @jira_textbox = TextCtrl.new(@kriek_panel, -1, '')
    @release_label = StaticText.new(@kriek_panel, -1, 'Release:  rel-3.0-', DEFAULT_POSITION, DEFAULT_SIZE)
    @release_textbox = TextCtrl.new(@kriek_panel, -1, '')
    @jira_link_html = HyperlinkCtrl.new(@kriek_panel, -1, 'Google', 'http://www.google.com/')
    #@jira_link_html.set_page("<a href='http://www.google.com/'>Gooooogle</a>")
    @revisions_label = StaticText.new(@kriek_panel, -1, 'Revisions:', DEFAULT_POSITION, DEFAULT_SIZE)
    @revisions_textbox = TextCtrl.new(@kriek_panel, -1, '', DEFAULT_POSITION, Size.new(-1, 3*17), TE_MULTILINE)
    @liquibase_label = StaticText.new(@kriek_panel, -1, 'Liquibase Changesets:', DEFAULT_POSITION, DEFAULT_SIZE)
    @liquibase_search_btn = Button.new(@kriek_panel, -1, 'Search')
    @liquibase_textbox = TextCtrl.new(@kriek_panel, -1, '', DEFAULT_POSITION, Size.new(-1, 2*17), TE_MULTILINE)
    @liquibase_add_btn = Button.new(@kriek_panel, -1, 'Add')
    @svn_log_label = StaticText.new(@kriek_panel, -1, 'Subversion Log:', DEFAULT_POSITION, DEFAULT_SIZE)
    @svn_log_fetch_btn = Button.new(@kriek_panel, -1, 'Fetch')
    @svn_log_textbox = TextCtrl.new(@kriek_panel, -1, '', DEFAULT_POSITION, Size.new(-1, 3*17), TE_MULTILINE)
    @preview_btn = Button.new(@kriek_panel, -1, 'Preview')
    
    evt_button(@preview_btn.get_id()) { |event| preview_btn_click(event) }
    @jira_textbox.evt_kill_focus() { |event| jira_textbox_kill_focus(event) }
    evt_close() { |event| destroy() }
    
    @kriek_panel_sizer = BoxSizer.new(VERTICAL)
    @kriek_panel.set_sizer(@kriek_panel_sizer)
    
    @top_panel = Panel.new(@kriek_panel)
    @top_panel_sizer = BoxSizer.new(HORIZONTAL)
    @top_panel.set_sizer(@top_panel_sizer)
    
    @top_panel_sizer.add(@jira_label, 0, GROW|ALL, 2)
    @top_panel_sizer.add(@jira_textbox, 0, GROW|ALL, 2)
    @top_panel_sizer.add(@release_label, 0, GROW|ALL, 2)
    @top_panel_sizer.add(@release_textbox, 0, GROW|ALL, 2)
    
    @svn_log_panel = Panel.new(@kriek_panel)
    @svn_log_panel_sizer = BoxSizer.new(HORIZONTAL)
    @svn_log_panel.set_sizer(@svn_log_panel_sizer)
    
    @svn_log_panel_sizer.add(@svn_log_label, 0, GROW|ALL, 2)
    @svn_log_panel_sizer.add_spacer(8)
    @svn_log_panel_sizer.add(@svn_log_fetch_btn, 0, GROW|ALL, 2)
    
    @liquibase_panel = Panel.new(@kriek_panel)
    @liquibase_panel_sizer = BoxSizer.new(HORIZONTAL)
    @liquibase_panel.set_sizer(@liquibase_panel_sizer)
    
    @liquibase_panel_sizer.add(@liquibase_label, 0, GROW|ALL, 2)
    @liquibase_panel_sizer.add_spacer(8)
    @liquibase_panel_sizer.add(@liquibase_search_btn, 0, GROW|ALL, 2)
    
    top_panel_sizer_item = @kriek_panel_sizer.add(@top_panel_sizer, 0, GROW|ALL, 2)
    puts top_panel_sizer_item
    puts top_panel_sizer_item.methods.sort.join(", ")
    puts top_panel_sizer_item.get_position
    #@kriek_panel_sizer.add(@jira_link_html, 0, GROW, 0)
    @kriek_panel_sizer.add_spacer(4)
    
    revisions_label_sizer_item = @kriek_panel_sizer.add(@revisions_label, 0, GROW|ALL, 2)
    puts revisions_label_sizer_item.get_position
    @kriek_panel_sizer.add(@revisions_textbox, 0, GROW|ALL, 2)
    @kriek_panel_sizer.add_spacer(8)
    
    @kriek_panel_sizer.add(@liquibase_panel_sizer, 0, GROW|ALL, 2)
    @kriek_panel_sizer.add(@liquibase_textbox, 0, GROW|ALL, 2)
    @kriek_panel_sizer.add_spacer(8)
    
    @kriek_panel_sizer.add(@svn_log_panel_sizer, 0, GROW|ALL, 2)
    @kriek_panel_sizer.add(@svn_log_textbox, 0, GROW|ALL, 2)
    @kriek_panel_sizer.add(@liquibase_add_btn, 0, ALL, 2)
    @kriek_panel_sizer.add(@preview_btn, 0, ALL, 2)
    
    show()
    fit()
  end
  
  def preview_btn_click(event)
    puts event.inspect
  end
  
  def jira_textbox_kill_focus(event)
    puts event.inspect
    puts event.get_event_object
    if event.get_event_object.nil?
      puts "get_event_object is nil?"
      return
    end
    puts "New Jira: KITT-" + event.get_event_object.get_value
  end
end

class KriekWx < App
  def on_init
    @kriek_frame = KriekFrame.new
  end
end

KriekWx.new.main_loop()
