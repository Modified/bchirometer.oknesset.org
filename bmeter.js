// Generated by CoffeeScript 1.7.1
(function() {
  $(function() {
    var page_turner, show_page;
    show_page = function(p) {
      console.log('Page to', p);
      $('section').hide().filter(p).show();
      return $('body').toggleClass('splash', p === '#splash');
    };
    page_turner = function(p) {
      return function() {
        return show_page(p);
      };
    };
    page.base('/');
    page('categories', page_turner('#categories'));
    page('agendas', function() {
      return show_page('#agendas');
    });
    page('results', page_turner('#results'));
    page('', function() {
      return show_page('#splash');
    });
    page();
    $('#categories-list').html(_.template($('#category-template').html(), {
      categories: categories
    }));
    $('#agendas-list').html(_.template($('#agenda-template').html(), {
      agendas: agendas
    }));
    return $('#agendas').on('click', 'button', function(ev) {
      var b, v;
      b = $(ev.target);
      v = (function() {
        switch (false) {
          case !b.hasClass('agree'):
            return 1;
          case !b.hasClass('indifferent'):
            return 0;
          case !b.hasClass('disagree'):
            return -1;
        }
      })();
      console.log('Voted', v, 'on', b.parent().attr('id'));
      return b.addClass('selected').siblings().removeClass('selected');
    });
  });

}).call(this);
