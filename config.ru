require 'sinatra/base'
require 'redcarpet'

require 'yaml'

CONFIG = 

class WorkshopRenderer < Redcarpet::Render::HTML
  def image(link, title, alt)
    link = "/#{link}" unless link[0] == '/'
    "<img src='#{link}' title='#{title}' alt='#{alt}'>"
  end

  def link(link, title, content)
  	link = '.' if link == '/'
  	"<a href='#{link}' title='#{title}'>#{content}</a>"
  end
end

class Application < Sinatra::Base

	set :config, YAML.load(File.read('config.yml'))
	set :renderer, Redcarpet::Markdown.new(WorkshopRenderer, fenced_code_blocks: true, extensions: {})

	get '/' do
		@labs = settings.config['labs']
		erb :index
	end

	get '/:id/?' do
		@id = params[:id]
		@lab = settings.config['labs'][@id]
		@lab['modules'] ||= settings.config['modules'].keys
		@modules = settings.config['modules']
		erb :lab
	end

	get '/:id/:module/?' do
		@id = params[:id]
		@module = params[:module]

		@md = File.read("#{@module}.md")
		@content = settings.renderer.render(@md)

		erb :module
	end

end

run Application