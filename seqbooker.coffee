#Common Meteor client/server code

HiseqBookings = new Meteor.Collection 'HiseqBookings'
MiseqBookings = new Meteor.Collection 'MiseqBookings'


if Meteor.isServer
    Meteor.methods({
        removeAll: () ->
            console.log 'Removing all items from collection...'
            HiseqBookings.remove({})
            MiseqBookings.remove({})
    })

    Meteor.publish('HiseqBookings', ->
        HiseqBookings.find({})
    )
    Meteor.publish('MiseqBookings', ->
        MiseqBookings.find({})
    )

if Meteor.isClient

    Session.set 'dom_is_ready', false

    Meteor.subscribe 'HiseqBookings'
    Meteor.subscribe 'MiseqBookings'

    Meteor.startup ->
        $('table#calendar').selectable({filter: 'td'})
        $( document ).tooltip(
            position:
                my: "center bottom+80",
                at: "center",
                using: ( position, feedback ) ->
                    $( this ).css( position )
                    $( "<div>" )
                        .addClass( "arrow" )
                        .addClass( feedback.vertical )
                        .addClass( feedback.horizontal )
                        .appendTo( this )
        )
        
    Template.main.ready = ->
        Session.get 'dom_is_ready'

    defaultView = new Date.today()
    Session.setDefault 'view', defaultView
    Session.setDefault 'notify', ''
    Session.setDefault 'sequencer', 'hiseq'

    Template.cal.calendar= ->
        calObj Session.get 'view' 

    Template.cal.rendered = ->
        $('#notify').hide()
        $('table#calendar').selectable({filter: 'td'})
        Meteor.setTimeout (->
            Session.set 'dom_is_ready', true
        ), 500
        #        notify_helper 'blind', 'Welcome. We\'re ready to take your booking.', 800, 5000

    Template.cal.events =
        'click #go-prev': (evt) ->
            evt.preventDefault
            view = Session.get 'view'
            newView = view.addMonths -1
            Session.set 'view', newView
        'click #go-next': (evt) ->
            evt.preventDefault
            view = Session.get 'view'
            newView = view.addMonths 1
            Session.set 'view', newView

    Template.control_panel.selected = ->
        Session.get 'sequencer'

    # Preserving elements associated with the JQuery tooltip as template rendering causes tooltip to become stuck
    Template.control_panel.preserve(['a.seq-selected', 'img#hiseq', 'img#miseq'])

    Template.control_panel.rendered = ->
        seq = Session.get 'sequencer'
        elem = '#'+seq
        $(elem).addClass('seq-selected')

    Template.booking_form.rendered = ->
        setFocus = @find('input[name=contact_name]')
        $(setFocus).focus()
                

    Template.booking_form.events =
        'click #booking-submit': (evt, template) ->
            evt.preventDefault()
            contactName = template.find('input[name=contact_name]').value
            contactPhone = template.find('input[name=contact_phone]').value
            projectDesc = template.find('input[name=project_desc]').value
            dates = []
            $('table#calendar').find('td.ui-selected').each ->
                datetime = $(this).children('time').attr 'datetime'
                dates.push datetime
            view = Session.get 'view'
            view = view.toString 'MMyy'
            return false
            if Session.equals 'sequencer','hiseq'
                HiseqBookings.insert { booking_dates : dates, view: view }
            else
                MiseqBookings.insert { booking_dates : dates, view: view }
            notify_helper 'blind', 'Booking created', '', 400
        'click #booking-cancel': (evt) ->
            evt.preventDefault()
            console.log 'cancel'
            $('.ui-widget-overlay').hide()
            $('#booking-form').hide()
            notify_helper 'blind', 'Booking was canceled', 'highlight', 400

    Template.control_panel.events =
        'click #btn-book': (evt) ->
            evt.preventDefault
            if not $('a.seq-select').children('img').hasClass('seq-selected')
                notify_helper 'shake', 'Please select a sequencer to book', 'highlight'
            else if $('table#calendar').find('td.ui-selected.booked').length > 0
                notify_helper 'shake', 'You have selected an already booked date(s)', 'highlight'
            else if $('table#calendar').find('td.ui-selected').length is 0
                message = 'You haven\'t selected any dates to book!'
                effect = 'shake'
                notify_helper effect, message, 'highlight'
            else
                $('.ui-widget-overlay').show()
                $('#booking-form').show()
        'click .seq-select': (evt) ->
            evt.preventDefault
            seq = $( evt.target ).attr('id')
            Session.set 'sequencer', seq
            $('a.seq-select').children('img').removeClass('seq-selected')
            $( evt.target ).addClass('seq-selected')
            notify_helper 'blind', seq.toUpperCase() + ' selected'


    notify_helper = (effect, message, state, time, timeout) ->
        state ?= 'default'
        time ?= 800
        timeout ?= 1500
        notify = {}
        notify.message = message
        notify.state = state
        Session.set 'notify', notify
        $('#notify').show(effect, '', time, notifyCB(timeout))

    notifyCB = (timeout)->
        setTimeout (->
            $('#notify:visible').fadeOut()
        ), timeout
    
    Template.notify.notify = ->
        Session.get 'notify'

    Template.admin.info = ->
        view = Session.get 'view'
        view = view.toString 'MMyy'
        bookings = HiseqBookings.find({view: view}).fetch()
        booked_dates = []
        bookings.forEach (booking) ->
            for date in booking.booking_dates
                booked_dates.push date
        booked_dates

    Template.control_panel.count = ->
        view = Session.get 'view'
        view = view.toString 'MMyy'
        if Session.equals('sequencer', 'hiseq')
            count= HiseqBookings.find({view: view}).count()
        else
            count= MiseqBookings.find({view: view}).count()


    Template.admin.events =
        'click .btn.destroy': (evt) ->
            Meteor.call 'removeAll'
            notify_helper 'drop', 'Collection items removed'
        'click .btn.show_view_bookings': (evt) ->
            $('#admin_info').show()


    calObj = (dateObj) ->
        calendar = {}
        calendar.month = dateObj.getMonth() + 1
        calendar.strMonth = dateObj.toString 'MMMM'
        calendar.year = dateObj.getFullYear()
        calendar.prevMonthDays = Date.getDaysInMonth calendar.year, (calendar.month - 1)
        calendar.nextMonth = calendar.month + 1
        calendar.prevMonth = calendar.month - 1
        if calendar.month is 1
            calendar.prevYear = calendar.year - 1
            calendar.prevMonth = 12
        else if calendar.month is 12
            calendar.nextYear = calendar.year + 1
            calendar.nextMonth = 1
        else
            calendar.prevYear = calendar.year
            calendar.nextYear = calendar.year
        calendar.firstDayCell = dateObj.moveToFirstDayOfMonth().getDay()
        calendar.todayDate= new Date().getDate() - 1
        calendar.lastDayCell = dateObj.moveToLastDayOfMonth().getDate() + calendar.firstDayCell - 1
        calendar.daysInMonth = dateObj.getDaysInMonth()
        if calendar.daysInMonth + calendar.firstDayCell > 35
            cellCount = 42
        else
            cellCount = 35
        cell = 0
        row_stop = 6
        dayNumThisMonth = 1
        nextDay = 0
        out = ''
        view = dateObj.toString 'MMyy'
        if Session.equals('sequencer', 'hiseq')
            bookings = HiseqBookings.find( { view: view } ).fetch()
        else
            bookings = MiseqBookings.find( {view: view } ).fetch()
        while cell < cellCount
            cssclass = ''
            if cell is calendar.todayDate and (defaultView.getMonth() + 1) is calendar.month
                cssclass+=" today"
            if cell >= calendar.firstDayCell and cell <= calendar.lastDayCell
                dayNum = dayNumThisMonth
                datetime = calendar.year + '-' + calendar.month + '-' + dayNum
            else
                if cell < calendar.firstDayCell
                    cssclass+=' prev'
                    diff = calendar.firstDayCell - cell - 1
                    dayNum = calendar.prevMonthDays - diff
                    datetime = calendar.prevYear + '-' + calendar.prevMonth + '-' + dayNum
                else
                    cssclass+=' next'
                    nextDay += 1
                    dayNum = nextDay
                    datetime = calendar.nextYear + '-' + calendar.nextMonth + '-' + dayNum
            bookings.forEach (booking) ->
                for date in booking.booking_dates
                    if date is datetime
                        cssclass+= " booked"
            cssclass+= ' day'
            td_cell='<td class=\'' + cssclass + '\'><time datetime="' + datetime + '">' + dayNum + '</time></td>'
            out+=td_cell
            if cell >= calendar.firstDayCell and cell <= calendar.lastDayCell
                dayNumThisMonth++
            cell++
            if cell > row_stop
                out+='</tr>'
                row_stop+=7
        calendar.html = out
        calendar

