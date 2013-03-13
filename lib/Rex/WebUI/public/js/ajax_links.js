function ajax_links() {

   var load_map = {
      '^/$': 'body',
      '^/logout$': 'body',
      '^/project/.*': '#content_area',
      '^/server/.*': '#content_area',
      'default': '#content_area'
   };

   $(document).ready(function() {

      $("a").each(function(id, obj) {

         if($(obj).attr("href") && $(obj).attr('class') != 'bound') {

			$(obj).addClass('bound')
            $(obj).click(function(event) {
               event.preventDefault();
               load_link($(this).attr("href"));
            });
         }
      });

   });

   function load_link(lnk) {
      // get the div where the content should be loaded
      var content_area;
      var nolayout = 1;

      for (var key in load_map) {
         var searcher = new RegExp(key);
         if(searcher.exec(lnk)) {
            console.log("Link must be loaded in: " + load_map[key]);
            content_area = load_map[key];
         }
      }

      if(! content_area) {
         console.log("Error finding div for link. Using default.");
         content_area = load_map["default"];
      }

      if(content_area == "body") {
         nolayout = 0;
         document.location.href = lnk;
      }
      else {
         $(content_area).load(lnk + '?nolayout=' + nolayout, function() {
            ajax_links();
         });
      }
   }
}

function ajax_form(form_id) {

	var form = $(form_id)[0];

	$.ajax({
		type: "POST",
		url: form.action,
		data: $(form_id).serialize(), // serializes the form data.
		success: function(data)
		{
			$('.form_error').text('');
			$('.form_error').hide();

			if (data.status == 'ok') {

				if (data.next) {
					//load_link(data.next); // maybe a more elegant way to do this, but I can't get the scope correct to call load_link method
					$(content_area).load(data.next + '?nolayout=1', function() { ajax_links(); });
				}
				else {
					alert('userid: ' + data.userid);
				}
			}
			else if (data.status == 'error') {

				for (var field in data.errors) {

					$('#' + field + '_error').text(data.errors[field]);
					$('#' + field + '_error').show();
				}
			}
		}
	});

	return false; // avoid to execute the actual submit of the form.
}

