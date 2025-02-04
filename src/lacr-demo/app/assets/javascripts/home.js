$(document).ready(function() {
  var dateFormat = 'yy-mm-dd';
  var minDate = '1398-01-01';
  var maxDate = '1511-12-31';
  // Initialise date fields for Advanced Search
  $( "#date_from" ).datepicker({
    showOtherMonths: true,
    selectOtherMonths: true,
    dateFormat: 'yy-mm-dd',
    minDate: $.datepicker.parseDate( dateFormat, minDate ),
    maxDate: $.datepicker.parseDate( dateFormat, maxDate ),
    defaultDate: $.datepicker.parseDate( dateFormat, minDate )
  }).on( "change", function() {
    $( "#date_to" ).datepicker( "option", "minDate", getDate( this ) );
  });

  $( "#date_to" ).datepicker({
    showOtherMonths: true,
    selectOtherMonths: true,
    dateFormat: dateFormat,
    minDate: $.datepicker.parseDate( dateFormat, minDate ),
    maxDate: $.datepicker.parseDate( dateFormat, maxDate ),
    defaultDate: $.datepicker.parseDate( dateFormat, maxDate )
  }).on( "change", function() {
    $( "#date_from" ).datepicker( "option", "maxDate", getDate( this ) );
  });

  function getDate( element ) {
    var date;
    try {
      date = $.datepicker.parseDate( dateFormat, element.value );
    } catch( error ) {
      date = null;
    }
    return date;
  }

  window.onresize = function() {
    responsiveScreen();
  };

  var responsiveScreen = function() {
    screenCheck = $(window).height() > 630 && $(window).width() > 1024;
    $.fn.fullpage.setFitToSection(screenCheck);
    $.fn.fullpage.setAutoScrolling(screenCheck);
  };

  // Initialise FullPageJS
    $('#fullpage').fullpage({
      anchors:['homepage', 'advsearch', 'about'],
      navigation: true,
      paddingTop: '60px',
      onLeave: function(index, nextIndex, direction){
        // Hide datepicer after leaving Advanced Search section
        if(index == 2){
          $( ".datepicker" ).datepicker('hide');
        }
      },
      // Focus earch input field
      afterLoad: function(anchorLink, index){
         if(index == 1 || index == 2){$('.simple-search').eq(index-1).focus();}
       }
    });

    // Initialise spelling variants slider
    $('#slider-spellVar').slider({ range: "max",
      min: 0, max: 4, value: 1,
      slide: function( event, ui ) {
        $( "#spellVar" ).val( ui.value );
      }
    });
    $( "#spellVar" ).val( $( "#slider-spellVar" ).slider( "value" ) );
});

$('#adv-search-nav').click(function(){
    $.fn.fullpage.moveTo('advsearch');
});

$('#about-nav').click(function(){
    $.fn.fullpage.moveTo('about');
});

$('#home-nav').click(function(){
    $.fn.fullpage.moveTo('homepages');
});

$('.fp-controlArrow-down').click(function(){
    $.fn.fullpage.moveSectionDown();
});
