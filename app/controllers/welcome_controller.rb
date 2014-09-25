class WelcomeController < ApplicationController
  def initialize
    super

    @code_ray_options = {tab_width: 2, line_numbers: :inline, css: :class}
    @fonts_code = <<ENDCODE
  # register UNICODE fonts if necessary
  # in this example I will register the Hebrew font David
  # from an existing PDF file.  
  unless CombinePDF::Fonts.get_font :david
    fonts = CombinePDF.new(Rails.root.join("app", "assets", "fonts", "david+bold.pdf").to_s).fonts(true)
    # I know the first font is David regular, after using the
    # ruby console and looking at the fonts array
    CombinePDF.register_font_from_pdf_object :david, fonts[0]
    # the second font of the array was the latin font for a newline and space... useless
    # the third was the david bold. I will now add that font.
    CombinePDF.register_font_from_pdf_object :david_bold, fonts[2]
  end
ENDCODE


    @number_pages_code = <<ENDCODE
  #####
  # number pages

  # set the first visible page number to the page where numbering starts
  # this assumes that the bates numbering include the numbering of the "cover page",
  # yet at the same time the numbering isn't visible on the "cover page"
  first_page_number += pdfs_pages_count[0] if params[:first_page_is_cover]

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
    number_location: [:top, :bottom],
    opacity: 0.75
  })
ENDCODE

    @title_page_code = <<ENDCODE
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

        # create and empty page object
        title_page = CombinePDF.create_page mediabox

        # write the content to the title page.
        # we will be usint the I18n "t" shortcut to write some of the data.
        # the rest of the data, like the title, we got from the form.
        title_page.textbox( "\#{t :bates_pdf_file} \#{pdfs_pages_count.length + first_index_number - 1}" ,
          max_font_size: 34,
          font: :david,
          y: (mediabox[3] - mediabox[1])/2 )
        title_page.textbox v[:title], max_font_size: 36, font: :david_bold
        title_page.textbox v[:date], max_font_size: 24, font: :david, height: (mediabox[3] - mediabox[1])/2

        # we will add the page object to the completed pdf object.
        # notice that page objects are created as "floating" pages,
        # not attached to any specific PDF file/object.
        completed_pdf << title_page
ENDCODE

    @combine_code = <<ENDCODE
  # itiriate through the different data sent from the client's browser's web form
  params.each do |k,v|
    # if the data is a file, add it to the 
    if k.to_s =~ /file_/
      # set the file_name variable in case an exception will be raised
      file_name = v[:name]

      # parse the pdf data
      # we will use the CombinePDF.parse method which allows us
      # to parse data without saving the PDF to the file system.
      # the data was saved in the form using base64, which we will need to decode.
      # (this is specific to my form which uses HTML5 File API)
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

#{@title_page_code}

        # now we are ready to add the pdf file data to the completed pdf object.
        # there is no need to add each page, we can add the pdf as a whole.
        # (it's actually faster, as the PDF page catalog isn't recomputed for each page)
        completed_pdf << pdf_file

        # we will add some data that will be used to create the
        # table of contents at a later stage.
        page_count = pdfs_pages_count.pop + 1
        pdfs_pages_count << page_count
        pdf_dates << v[:date]
        pdf_titles << v[:title]
      end
    end
  end
ENDCODE


    @stub_bates_code = <<ENDCODE
  ##########
  # create the index pdf

  # set the fonts and formatting for the table of contents.
  #
  # also, add an empty array for the table data.
  #
  # the table data array will contain arrays of String objects, each one
  # corresponding to a row in the table.
  table_options = {  font: :david,
    header_font: :david_bold,
    max_font_size: 12,
    column_widths: [3, 10, 30, 4],
    table_data: [] }

  # set the table header array.
  # this is an array of strings. we will use the I18n .t shortcut
  # to chose the localized strings
  table_options[:headers] = [ (t :bates_pdf_file),
    (t :bates_pdf_date),
    (t :bates_pdf_title),
    (t :bates_pdf_page) ]

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
      table_options[:table_data] << [ (first_index_number + index_count).to_s,
        pdf_dates[i], pdf_titles[i], page_number ]

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
  if I18n.locale == :he
    table_options[:direction] = :rtl
  end

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
  # we will use the I18n .t shortcut to choose the text to write down.
  title_page.textbox (t :bates_pdf_index),
    { y: ((title_page.mediabox[3] - title_page.mediabox[1])*0.91),
      height: ((title_page.mediabox[3] - title_page.mediabox[1])*0.03),
      font: :david,
      max_font_size: 24,
      text_valign: :bottom  }

  # now we will add the index_pdf to the BEGINING of the completed pdf.
  # for this we will use the >> operator instead of the << operator.
  completed_pdf >> index_pdf

#{@number_pages_code}

ENDCODE
    @bates_code = @fonts_code + "\n" + @combine_code + "\n" + @stub_bates_code

    @code = <<ENDCODE
# There is no action to perform without any files.
return if params[:file_0].nil?
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

  # set the output file name
  # this will be used to name the download for the client's browser
  output_name = ( Date.today.strftime '%Y%m%d output.pdf' )

  # get some paramaters that will be used while combining pages
  params[:bates] ||= {}
  first_page_number = params[:bates][:first_page_number] || 1
  first_index_number = params[:bates][:first_index_number] || 1

  # we will add an option for the stamping to ignore the first pdf
  # this is useful for the court cases that use bates numbering
  # (the "cover PDF" will be the briefs of submissions that contain exhibits to be bates stamped)
  params[:bates][:first_pdf_is_cover] ||= false
  ignore_first_file = (params[:bates][:first_pdf_is_cover] == "1")
  first_page = nil

  # we will pick some data up while running combining
  # the different pdf files.
  # this will be used for the table of contents later on.
  pdfs_pages_count = []
  pdf_dates = []
  pdf_titles = []

  # we will be creating title pages before each PDF file.
  # the title pages will be sized using the mediabox variable
  # wich will be set with the dimentions of each pdf file's first page.
  mediabox = nil

#{@bates_code}

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
    # we will send the raw PDF data stream through the .send_data method, setting
    # the type of the stream and the file name for the stream.
    send_data completed_pdf.to_pdf, type: 'application/pdf', filename: output_name

    # finish execution
    return

  else

    # inform the client there was an unknown error.
    redirect_to bates_url, notice: (I18n.t :bates_unknown_zero_pages_error)
  end

rescue Exception => e
  # if an exception was raised, tell the user which PDF caused the exception
  redirect_to bates_url, notice: ( I18n.t(:bates_file_unsupported_error) + "\\n\#{file_name}")
end
ENDCODE
  @code_wrapper = @code.gsub(@bates_code, "############\n# MY CODE WILL GO HERE\n############")
  @stub_combine = <<ENDCODE
  # container for the complete pdf
  # the complete pdf container will hold all
  # the merged pdf data.
  completed_pdf = CombinePDF.new

  # itirate through the files array - this is stub code to be completed later:
  files.each do |file|
      # parse the pdf data
      # we will use the CombinePDF.parse method which allows us
      # to parse data without saving the PDF to the file system.
      # the data was saved in the form using base64, which we will need to decode.
      # (this is specific to my form which uses HTML5 File API)
      pdf_file = CombinePDF.parse(
        Base64.urlsafe_decode64(
          v[:data].slice( "data:application/pdf;base64,".length,
            v[:data].length )) )
      completed_pdf << pdf_file
  end

  # send the data WITHOUT saving to the file system
  send_data completed_pdf.to_pdf, type: 'application/pdf', filename: output_name
ENDCODE
    @code_without_remarks = (@code.lines.delete_if {|l| l =~ /^[\s]*\#[\w\s]*/}).join
  end
  def welcome
    @content = t(:welcome_page)
    @content.gsub! "combine_pdf", ("\"combine_pdf\":https://rubygems.org/gems/combine_pdf")
    @content.gsub! "bates", ("\"bates\":%s" % bates_path)
    @content.gsub! /Let's get started!/, ("\"Let’s get started!\":%s" % code_path)
    render inline: RedCloth.new( @content ).to_html, layout: true
  end

  def combine
    eval @code
  end

  def code
  end

  def number
  end

  def tables
  end

  def fonts
  end

  def bates
    eval @code
  end
end
