# CombinePDF Demo

This project holds a demo application for the [`combine_pdf` gem](https://github.com/boazsegev/combine_pdf), so you can learn how to use the code, copy and adjust for your needs.

The project uses a simplified implementation of [The Plezi framework](http://www.plezi.io) rather than using [Rails](http://rubyonrails.org). This should allow to easily read the code for the actual PDF handling, in the [controller class](https://github.com/boazsegev/combine_pdf_demo/blob/master/pdf_controller.rb).

Although using Plezi's websocket features to upload and download PDF data would have been a better approach, a simplified Http based approach was favored, so that both [the form](https://github.com/boazsegev/combine_pdf_demo/blob/master/templates/bates.html.slim) and [the controller](https://github.com/boazsegev/combine_pdf_demo/blob/master/pdf_controller.rb) could be easily copied over to Rails applications with only minor adjustments.

You can see [the demo at work](https://combine-pdf-demo.herokuapp.com) (it's hosted on Heroku). I know the design is less than beautiful, feel free to contribute a nicer design, if you wish.
