"use strict";

/* global jQuery, Desk, Handlebars, HandlebarsIntl, filesize, location */

(function($) {
  HandlebarsIntl.registerWith(Handlebars);
  Handlebars.registerHelper('formatSize', function(size) {
    return filesize(size);
  });


  const INTL = {
      locales: 'en-US',
      formats: {
        date: {
          short: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric'
          },
          long: {
            day: 'numeric',
            month: 'long',
            year: 'numeric'
          }
        },
        time: {
          short: {
            hour: 'numeric',
            minute: 'numeric'
          },
          long: {
            hour: 'numeric',
            minute: 'numeric',
            seconds: 'numeric'
          }
        }
      }
    };
  
  class FileExplorer {
    constructor(sr) {
      this.sr       = sr;
      this.caseId   = sr.context.environment.case.id;
      this.agentId  = sr.context.userId;
      this.template = Handlebars.compile($('#template').html());
      this.element  = $('tbody');
      this._sort    = 'name';
      
      $('#sort button').click(this.changeSort.bind(this));
      $('tbody').on('click', 'button', this.action.bind(this));
      $("#file-upload").fileinput({
        uploadUrl: '/folders/' + this.caseId + '/files',
        showPreview: false,
        uploadExtraData: { caseId: this.caseId }
      }).on('fileuploaded', () => {
        $('#file-upload').fileinput('clear').fileinput('enable').fileinput('refresh', { showUpload: true });
        this._fetchFiles();
      });
    }
    
    set caseId(val) {
      this._caseId = val;
      this._fetchFiles();
    }
    
    get caseId() {
      return this._caseId;
    }
    
    set files(val) {
      this._files = val;
      this._render();
    }
    
    get files() {
      return this._files.sort(this._sortBy.bind(this));
    }
    
    set sort(val) {
      this._sort = val;
      this._render();
    }
    
    get sort() {
      return this._sort;
    }
    
    _sortBy(a, b) {
      if (this.sort == 'size') {
        if (a.size < b.size) return -1;
        if (a.size > b.size) return 1;
        return 0;
      } else if (this.sort == 'modified') {
        if (a.modified < b.modified) return -1;
        if (a.modified > b.modified) return 1;
        return 0;
      } else {
        if (a.name.toUpperCase() < b.name.toUpperCase()) return -1;
        if (a.name.toUpperCase() > b.name.toUpperCase()) return 1;
        return 0;
      }
    }
    
    _fetchFiles() {
      $.get('/folders/' + this.caseId + '/files', (files) => {
        this.files = files;
      });
    }
    
    _render() {
      this.element.html(this.template({
        files: this.files
      }, { data: { intl: INTL }}));
      $('[data-toggle="tooltip"]').tooltip();
    }
    
    changeSort(evt) {
      $('#sort button').removeClass('active');
      this.sort = $(evt.target).addClass('active').data('sort');  
    }
    
    action(evt) {
      var btn = $(evt.currentTarget)
        , url = '/folders/' + this.caseId + '/files/' + btn.data('file');
      btn.find('i').toggleClass('spinning');
      
      if (btn.hasClass('btn-danger')) {
        $.ajax('/folders/' + this.caseId + '/files/' + btn.data('file'), {
          method: 'DELETE'
        }).done(this._fetchFiles.bind(this));
      } else if (btn.hasClass('btn-primary')) {
        $('<a>').attr('href', url)
                .attr('target', '_blank')
                .get(0).click();
        btn.find('i').toggleClass('spinning');
      } else {
        Desk.canvas.client.ajax(this.sr.context.environment.case.url + '/replies/draft', {
          client: this.sr.client,
          method: 'GET',
          success: function(data) {
            if (200 === data.status) {
              Desk.canvas.client.ajax(this.sr.context.environment.case.url + '/replies/draft', {
                client: this.sr.client,
                method: 'PATCH',
                data: JSON.stringify({ body: data.payload.body + 'https://' + location.host + url }),
                success: function() {
                  btn.find('i').toggleClass('spinning');
                }
              });
            }
          }.bind(this)
        });
      }
    }
  }
  
  Desk.canvas(function() {
    Desk.canvas.client.refreshSignedRequest(function(data) {
      if (data.status === 200) {
        var sr = data.payload.response.split('.')[1];
        new FileExplorer(JSON.parse(Desk.canvas.decode(sr)));
      }
    });
  });
}(jQuery));