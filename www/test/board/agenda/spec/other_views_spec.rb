#
# Other views
#

require_relative 'spec_helper'

feature 'other reports' do
  it "should support search" do
    visit '/2015-02-18/search?q=ruby'

    expect(page).to have_selector 'pre', text: 'Sam Ruby'
    expect(page).to have_selector 'h4 a', text: 'Qpid'
  end

  it "should support comments" do
    visit '/2015-02-18/comments'

    expect(page).to have_selector 'h4 a', text: 'Hama'
    expect(page).to have_selector 'pre', text: 'sr: Reminder email sent'
  end

  it "should support queued/pending approvals and comments" do
    visit '/2015-02-18/pending'

    expect(page).to have_selector 'a[href="W3C-Relations"]', 
      text: 'W3C Relations'
    expect(page).to have_selector 'dt a[href="BookKeeper"]', text: 'BookKeeper'
    expect(page).to have_selector 'dd p', text: 'Nice report!'
  end

  it "should highlight and crosslink action items" do
    visit '/2015-02-18/Action-Items'

    expect(page).to have_selector 'span.commented', text: /^\s*Status:$/
    expect(page).to have_selector 'a.missing[href=Deltacloud]',
      text: '[ Deltacloud ]'
    expect(page).to have_selector 'a.reviewed[href=ACE]', text: '[ ACE ]'
    expect(page).to have_selector '.backlink[href="Discussion-Items"]',
      text: 'Discussion Items'
    expect(page).to have_selector '.nextlink[href="Unfinished-Business"]',
      text: 'Unfinished Business'
    expect(page).to have_selector 'a[href="http://s.apache.org/jDZ"]'
  end

  it "should hypertext minutes" do
    visit '/2015-02-18/January-21-2015'

    expect(page).to have_selector \
     'a[href="https://svn.apache.org/repos/private/foundation/board/board_minutes_2015_01_21.txt"]',
     text: 'board_minutes_2015_01_21.txt'
  end
end