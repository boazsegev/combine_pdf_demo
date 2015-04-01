class PDFController
	def index
		@bates_numbering = %w{Center Left Right}
		@bates_numbering << "None (merge without indexing)"
		@notice = flash[:notice]
		render :bates
	end

	def bates
		# redirect back to the form page if there's no posted data.
		return redirect_to '' unless params[:file] && params[:file][0]

		# catch any exception and tell the user which PDF caused the exception.
		begin
		
			# set the file_name variable
			# this will be used in case an exception is caught
			# to state which file caused the exception.
			file_name = ''
		
			# container for the complete pdf
			# the complete pdf container will hold all
			# the merged pdf data.
			completed_pdf = CombinePDF.new
		
			# get the output file name
			# this will be used to name the download for the client's browser
			output_name = params[:bates][:output].to_s + '.pdf'
		
			# get some paramaters that will be used while combining pages
			params[:bates] ||= {}
			first_page_number = params[:bates][:first_page_number] || 1
			first_index_number = params[:bates][:first_index_number] || 1
		
			# we will add an option for the stamping to ignore the first pdf
			# this is useful for the court cases that use bates numbering
			# (the "cover PDF" will be the briefs of submissions that contain exhibits to be bates stamped)
			ignore_first_file = params[:bates][:first_pdf_is_cover]
			first_page = nil
		
			# we will pick some data up while running combining the different pdf files.
			# this will be used for the table of contents later on.
			pdfs_pages_count = []
			pdf_dates = []
			pdf_titles = []
		
			# we will be creating title pages before each PDF file.
			# the title pages will be sized using the mediabox variable
			# wich will be set with the dimentions of each pdf file's first page.
			mediabox = nil
		
			# register UNICODE fonts if necessary
			# in this example I will register the Hebrew font David from an existing PDF file.  
			unless CombinePDF::Fonts.get_font :david
				# if your running Rails, consider Rails.root instead of Root
				fonts = CombinePDF.new(Root.join("public", "fonts", "david+bold.pdf").to_s).fonts(true)
				# I know the first font is David regular, after using the
				# ruby console and looking at the fonts array for the file.
				CombinePDF.register_font_from_pdf_object :david, fonts[0]
				# the second font of the array was the latin font for a newline and space... useless
				# the third was the david bold. I will now add that font.
				CombinePDF.register_font_from_pdf_object :david_bold, fonts[2]
			end
		
			# itiriate through the different data sent from the client's browser's web form
			params[:file].each do |k,v|
				# set the file_name variable in case an exception will be raised
				file_name = v[:name]
	
				# parse the pdf data
				# we will use the CombinePDF.parse method which allows us
				# to parse data without saving the PDF to the file system.
				# our javascript encoded the file data using base64, which we will need to decode.
				# (this is specific to my form which uses the HTML5 File API in this specific manner)
				pdf_file = CombinePDF.parse(
					Base64.urlsafe_decode64(
						v[:data].slice( "data:application/pdf;base64,".length,
							v[:data].length )) )
	
				# we will use the pages array a few times, so in order to avoid
				# recomputing the array every time, we will save it to a local variable.
				pdf_file_pages = pdf_file.pages
	
				# we will add the page count to the page count array,
				# used by the table of contents
				pdfs_pages_count << pdf_file_pages.length
	
				######
				# create and add title page to arrays.
	
				if ignore_first_file && first_page.nil?
					# if the first PDF file is a "cover page" PDF,
					# we will not add a title, nor add the file.
					# instead we will save the data in a variable to add it after we're done
					pdf_dates << ""
					pdf_titles << ""
					first_page = pdf_file
				else
					# set title page mediabox size
					# the mediabox data (page size) is contained in the page's
					# :CropBox or :MediaBox keys (pages are Hash objects).
					mediabox ||= pdf_file_pages[0][:CropBox] || pdf_file_pages[0][:MediaBox]

					# create a title page unless we're only merging or there is no indexing
					if params[:bates][:should_index] && params[:bates][:numbering] != 3
	
						# create an empty page object
						title_page = CombinePDF.create_page mediabox
		
						# write the content to the title page.
						# we will be using the I18n.t shortcut to write some of the data.
						# the rest of the data, like the title, we got from the form.
						title_page.textbox( "#{params[:bates][:title_type]} #{pdfs_pages_count.length + first_index_number - (ignore_first_file ? 2 : 1)}" ,
							max_font_size: 34,
							font: :david,
							y: (mediabox[3] - mediabox[1])/2 ) unless params[:bates][:title_type].to_s.empty?
						title_page.textbox v[:title], max_font_size: 36, font: :david_bold
						title_page.textbox v[:date], max_font_size: 24, font: :david, height: (mediabox[3] - mediabox[1])/2
		
						# we will add the page object to the completed pdf object.
						# notice that page objects are created as "floating" pages,
						# not attached to any specific PDF file/object.
						completed_pdf << title_page

						# we will add some data that will be used to create the
						# table of contents at a later stage.
						page_count = pdfs_pages_count.pop + 1
						pdfs_pages_count << page_count
						pdf_dates << v[:date]
						pdf_titles << v[:title]
					end
	
	
					# now we are ready to add the pdf file data to the completed pdf object.
					# there is no need to add each page, we can add the pdf as a whole.
					# (it's actually faster, as the PDF page catalog isn't recomputed for each page)
					completed_pdf << pdf_file
				end
			end
		
			##########
			# create the index pdf...
			# ...unless we're only merging or there is no indexing
			if params[:bates][:should_index] && params[:bates][:numbering] != 3

				# set the fonts and formatting for the table of contents.
				#
				# also, add an empty array for the table data.
				#
				# the table data array will contain arrays of String objects, each one
				# corresponding to a row in the table.
				table_options = {  font: :david,
					header_font: :david_bold,
					max_font_size: 12,
					column_widths:  (params[:bates][:date_header].to_s.empty? ? [3, 40, 4] : [3, 10, 30, 4]),
					table_data: [] }
			
				# set the table header array.
				# this is an array of strings. we will use the I18n .t shortcut
				# to chose the localized strings
				table_options[:headers] = [ params[:bates][:number_header] , # (I18n.t :bates_pdf_file),
					(params[:bates][:date_header].to_s.empty? ? nil : params[:bates][:date_header]),
					params[:bates][:title_header],
					params[:bates][:page_header] ]
				table_options[:headers].compact!
			
				# by default, there are 25 rows per page for table pdf created by CombinePDF
				# we can override this in the formatting (but we didn't).
				#
				# the 25 rows include 1 header row per page - so there are only 24 effective rows.
				#
				# we will calculate how many pages the table of contents pdf will have once completes,
				# so we can add the count to the page numbers in the index.
				index_page_length = pdfs_pages_count.length / 24
				index_page_length += 1 if pdfs_pages_count.length % 24 > 0
			
				# set the page number for the first entry in the table of contents.
				page_number = first_page_number + index_page_length
			
				# set the index count to 0, we will use it to change the index for each entry. 
				# we need a different variable in case the first PDF file is a "cover page".
				index_count = 0
			
				# itirate over the data we collected before
				# and add it to the table data.
				pdfs_pages_count.each_index do |i|
					# add the data unless it is set to be ignored
					unless ignore_first_file
			
						# add an array of strings to the :table_data array,
						# representing a row in our table.
						# remember there might not be a date column.
						if params[:bates][:date_header].to_s.empty?
							table_options[:table_data] << [ (first_index_number + index_count).to_s,
									pdf_titles[i], page_number ]
						else
							table_options[:table_data] << [ (first_index_number + index_count).to_s,
									pdf_dates[i],
									pdf_titles[i], page_number ]
						end

						# if the data was added to the index table, bump the index count
						index_count += 1
			
					end
			
					# make sure future data will not be ignored
					ignore_first_file = false
			
					# add the page count to the page number, so that the next
					# index's page number is up to date.
					page_number += pdfs_pages_count[i]
			
				end
			
				# if out current locale is hebrew, which is a right to left language,
				# set the direction for the table to Right-To-left (:rtl).
				#
				# notice that RTL text should be automatically recognized, but that
				# feature isn't available (and shouldn't be available) for tables.
				if params[:bates][:dir] == 'rtl'
					table_options[:direction] = :rtl
				end

				# if there is table data, we will create an index pdf.
				unless table_options[:table_data].empty?
			
					# create the index PDF from the table data and options we have.
					index_pdf = CombinePDF.create_table table_options
				
					# We will now add the words "Table of Contents" (or the I18n equivilant)
					# to the first page of our new index_pdf PDF object.
					#
					# the table PDF object was created by CombinePDF using writable PDF pages,
					# so we have properties like .mediabox and methods like .textbox
					# at our disposal.
				
					# get the first page of the index_pdf object, we will use this reference a lot.
					title_page = index_pdf.pages[0] 
				
					# write the textbox, using the mediabox page data [x,y,width,height] to place
					# the text we want to write.
					#
					# we will use the I18n.t shortcut to choose the text to write down.
					title_page.textbox params[:bates][:index_title],
						{ y: ((title_page.mediabox[3] - title_page.mediabox[1])*0.91),
							height: ((title_page.mediabox[3] - title_page.mediabox[1])*0.03),
							font: :david,
							max_font_size: 24,
							text_valign: :bottom  }
				
					# now we will add the index_pdf to the BEGINING of the completed pdf.
					# for this we will use the >> operator instead of the << operator.
					completed_pdf >> index_pdf

				end

			end
		
			#####
			# number pages
			# unless no numbering
			if params[:bates][:numbering] != 3
				# list the numbering options
				numbering_options = [[:top, :bottom], [:top_left, :bottom_left], [:top_right, :bottom_right]]

				# set the first visible page number to the page where numbering starts
				# this assumes that the bates numbering include the numbering of the "cover page",
				# yet at the same time the numbering isn't visible on the "cover page"
				first_page_number += pdfs_pages_count[0] if params[:bates][:first_pdf_is_cover]
			
				# call the page numbering method and
				# add the special properties we want for the textbox
				completed_pdf.number_pages({ start_at: first_page_number,
					font_name: :david,
					font_size: 14,
					font_color: [0,0,0.4],
					box_color: [0.8, 0.8, 0.8],
					border_width: 1,
					border_color: [0.3,0.3,0.3],
					box_radius: 8,
					number_location: numbering_options[ params[:bates][:numbering] ],
					opacity: 0.75
				})
			end

			####
			# finish up

			# add first file if it was skipped
			if !first_page.nil?
				completed_pdf >> first_page
			end
		
			# send the completed PDF to the client.
			# if the completed PDF is empty, raise an error.
			if completed_pdf.pages.length > 0
				#make sure the PDF version is high enough for the opacity we used in the page numbering.
				completed_pdf.version = [completed_pdf.version, 1.6].max
		
				# we will format the PDF to a pdf file WITHOUT saving it to the file system,
				# using the .to_pdf method (instead of the .save method).
				# we will send the raw PDF data stream.
				# on Rails use the .send_data method, setting the type of the stream and the file name for the stream.
				# send_data , type: 'application/pdf', filename: output_name
				# but I'm running this on Plezi, which has a similar method...
				send_data completed_pdf.to_pdf, type: 'application/pdf', filename: output_name
				
				# finish execution
				return true
		
			else
		
				# inform the client there was an unknown error.
				redirect_to '', notice: (I18n.t :bates_unknown_zero_pages_error)
			end
		
		rescue Exception => e
			PL.error e
			PL.error "The file causing the exception is: #{file_name}"
			# if an exception was raised, tell the user which PDF caused the exception
			redirect_to '', notice: ( I18n.t(:bates_file_unsupported_error) + "\n#{file_name}")
			return true
		end
	end

	def code
		redirect_to 'https://github.com/boazsegev/combine_pdf_demo/blob/master/app/controllers/pdf_controller.rb'
	end
	protected

	def link_to text, path, options={}
		extra = ""
		options.each {|k,v| extra << " #{k}='#{v}'"}
		"<a href='#{path}'#{extra}>#{text}</a>"
	end
end