class StaticController < ApplicationController
  before_filter :authenticate
  
  def pages
    page_name = params[:page]
    map = {
        schema: {desc: "Schema", file: "db/schema.rb"},
        routes: {desc: "Routes", file: "config/routes.rb"}
      }

    mapped_file = map[page_name.to_sym]
    if mapped_file then
      @page_desc = mapped_file[:desc]
      @contents = file_to_html(Rails.root.to_s + "/" + mapped_file[:file])

    else
      @page_desc = page_name
      @contents = "... is unknown"
      render
    end
  end
  
  private
  
  def file_to_html(contents)
    html = '<div style="font-family:monospace; font-size:large">'
    File.open(contents, 'r') do |f|
      f.each do |line|
        html += line.gsub(' ', '&nbsp;') + '<br>'
      end
    end
    html += '</div>'
  end
end
