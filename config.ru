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

	set :config, Dir.glob('labs/*.yml').map{ |lab| [lab, YAML.load(File.read("#{lab}"))] }
		.inject({}) { |labs, lab| id = File.basename(lab[0]).gsub('.yml', ''); labs[id] = lab[1]; labs }

	set :modules, YAML.load(File.read('modules.yml'))
	set :markdown, Redcarpet::Markdown.new(WorkshopRenderer, fenced_code_blocks: true, extensions: {})

	get '/' do
		if ENV['DEFAULT_LAB']
			redirect "/#{ENV['DEFAULT_LAB']}"
		else
			@labs = settings.config
			erb :index
		end
	end

	get '/:id/?' do
		@id = params[:id]
		@lab = settings.config[@id]
		@mods = settings.config[@id]['modules'] || settings.modules['modules'].keys.clone
		@modules = settings.modules['modules']

		@mods.each do |mod|
			settings.modules['modules'][mod]['requires'].each do |m|
				@mods << m unless @mods.include?(m)
			end if settings.modules['modules'][mod]['requires']
		end

		erb :lab
	end

	get '/:id/:module/?' do
		@id = params[:id]
		@module = params[:module]

		case 
			when File.exists?("modules/#{@module}.md")
				@src = File.read("modules/#{@module}.md")
				@content = settings.markdown.render(@src)
			when File.exists?("modules/#{@module}.adoc")
				@src = File.read("modules/#{@module}.adoc")
				attributes = ENV.clone
				settings.config[@id]['vars'].each_key do |key|
				  attributes[key] = settings.config[@id]['vars'][key] unless attributes[key]
				end if settings.config[@id]['vars']
 				@content = Asciidoctor.render(@src, attributes: attributes)
		end

		erb :module
	end

end

run Application