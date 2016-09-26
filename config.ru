require 'sinatra/base'

require 'redcarpet'
require 'asciidoctor'

require 'yaml'

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
	set :markdown, Redcarpet::Markdown.new(WorkshopRenderer, fenced_code_blocks: true, extensions: {})

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

		case 
			when File.exists?("#{@module}.md")
				@src = File.read("#{@module}.md")
				@content = settings.markdown.render(@src)
			when File.exists?("#{@module}.adoc")
				@src = File.read("#{@module}.adoc")
				@content = Asciidoctor.convert(@src, header_footer: true, safe: :safe)
		end

		erb :module
	end

end

run Application