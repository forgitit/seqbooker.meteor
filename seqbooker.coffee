###########################################################
#Common Meteor client/server code

HiseqBookings = new Meteor.Collection 'HiseqBookings'
MiseqBookings = new Meteor.Collection 'MiseqBookings'

###########################################################
# Server
if Meteor.isServer

    Meteor.startup( ->
        process.env.MAIL_URL = "smtp://sign-up%40seqbooker.mailgun.org:wxy354KLOP99CX@smtp.mailgun.org:587"
    )

    Meteor.methods({
        removeAll: () ->
            console.log 'Removing all items from collection...'
            HiseqBookings.remove({})
            MiseqBookings.remove({})

        uploadFile: (file) ->
            console.log file
        sendEmail: (to, from, subject, text) ->
            check([to, from, subject, text], [String])
            this.unblock()
            Email.send(
                to: to
                from: from
                subject: subject
                text: text
            )
        initNewUser: (email) ->
            if Meteor.users.find('emails.address': email).count() > 0
                console.log email
                console.log 'email exists'
                return false
            else
                uid = Accounts.createUser(email: email)
                Meteor.call('sendEmail',
                    email,
                    'admin@seqbooker.plantenergy.uwa.edu.au',
                    'SeqBooker Sign-up Request',
                    'Sign up!',
                    (error, result) ->
                        if error
                            return false
                        else
                            return true
                )
    })

    Meteor.publish('HiseqBookings', ->
        user = Meteor.users.findOne(
            _id: this.userId
        )
        if user and user.emails[0].verified
            HiseqBookings.find({})
        else
            HiseqBookings.find({})
    )
    Meteor.publish('MiseqBookings', ->
        user = Meteor.users.findOne(
            _id: this.userId
        )
        if user and user.emails[0].verified
            MiseqBookings.find({})
        else
            MiseqBookings.find({})
    )
    Meteor.publish('userData', ->
        Meteor.users.find({_id: this.userId})
    )
    Accounts.config(
        sendVerificationEmail: true
        forbidClientAccountCreation: false
    )

    Accounts.emailTemplates.siteName = 'SeqBooker'
    Accounts.emailTemplates.from = 'admin@seqbooker.plantenergy.uwa.edu.au'

###########################################################
# Client
if Meteor.isClient

    defaultView = new Date.today()
    Session.setDefault 'view', defaultView
    Session.setDefault 'notify', ''
    Session.setDefault 'sequencer', 'hiseq'
    Session.setDefault 'bookInfo', false
    Session.setDefault 'bookForm', false

    Session.set 'dom_is_ready', false

    Meteor.subscribe 'HiseqBookings'
    Meteor.subscribe 'MiseqBookings'

    Deps.autorun( ->
        if Meteor.user()
            Meteor.subscribe 'userData', Meteor.userId
    )

    Template.login.logged_in = ->
        if Meteor.user()
            Meteor.user().emails[0].address
        else
            false

    Template.login.events =
        'keydown': (evt, template) ->
            form = template.find('form:visible')
            if evt.which is 13
                if $(form).attr('id') is 'sign-in-form'
                    login_helper(form)
                else if $(form).attr('id') is 'create-account-form'
                    account_create_helper(form)
                else if $(form).attr('id') is 'change-password-form'
                    change_password_helper(form)
            else if evt.which is 27
                $(form).hide()
                $('#login').show()
        'click #login': (evt,template) ->
            evt.preventDefault()
            $(evt.target).hide()
            form = template.find('form#sign-in-form')
            $(form).show()
            $(form).find('input[name="email_address"]').focus()
        'click #logout': (evt, template) ->
            evt.preventDefault()
            $(evt.target).hide()
            form = template.find('form#sign-out-form')
            $(form).show()
        'click #submit-logout': (evt, template) ->
            evt.preventDefault()
            Meteor.logout()
            form = template.find('form:visible')
            $(form).hide()
        'click .close-sign-in': (evt, template) ->
            evt.preventDefault()
            form = template.find('form:visible')
            $(form).hide()
            span = template.find('span')
            $(span).hide()
            $('#login').show()
        'click #submit-login': (evt, template) ->
            evt.preventDefault()
            form = template.find('form:visible')
            login_helper(form)
        'click #account-create': (evt, template) ->
            evt.preventDefault()
            form = template.find('form:visible')
            $(form).hide()
            form = template.find('form#create-account-form')
            $(form).show()
            $(form).find('input[type="text"]').focus()
        'click #submit-account': (evt, template) ->
            evt.preventDefault()
            form = template.find('form:visible')
            account_create_helper(form)
        'click #request-change-password': (evt, template) ->
            evt.preventDefault()
            form = template.find('form:visible')
            $(form).hide()
            $('#change-password-form').show()
        'click #submit-password-change': (evt, template) ->
            evt.preventDefault()
            form = template.find('form:visible')
            $(form).find('input[name="old_password"]').focus()
            change_password_helper(form)
        'click #request-forgot-password': (evt, template) ->
            evt.preventDefault()

    change_password_helper = (form) ->
        old = $(form).find('input[name="old_password"]').val()
        new_pass = $(form).find('input[name="new_password"]').val()
        Accounts.changePassword(old, new_pass, (err) ->
            if err
                console.log 'error'
                $(form).find('small').show().fadeOut(2500)
                return false
            else
                console.log 'success'
                $(form).find('small').text('Updating details...').show().fadeOut(2500)
                $('#login').show()
                $(form).hide()
        )

    login_helper = (form) ->
        email = $(form).find('input[name="email_address"]').val()
        password= $(form).find('input[name="password"]').val()
        error = $(form).find('span')
        if not email
            error.text('No email supplied!').show().fadeOut(2500)
            return false
        if not password
            error.text('No password supplied!').show().fadeOut(2500)
            return false
        Meteor.loginWithPassword(email, password, (err) ->
            if err
                error.text('Server error').show().fadeOut(2500)
            else
                $('form#sign-in').hide()
        )

    account_create_helper = (form) ->
        input = $(form).find('input[name="email_address"]')
        email = $(input).val()
        err = $(form).find('span')
        if not email
            $(err).text('No email supplied!').show().fadeOut(2500)
            return false
        Meteor.call('initNewUser', email, (error, result) ->
            if not error
                $(form).hide()
                console.log 'enrollment sent'
            else
                $(error).text('Email address already in use!').show().fadeOut(2500)
                return false
        )


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
        Meteor.setTimeout (->
            Session.set 'dom_is_ready', true
        ), 500

    Template.main.ready = ->
        Session.get 'dom_is_ready'

    Template.cal.helpers(
        calendar: ->
            calObj Session.get 'view'
        bookable: ->
            Session.get 'bookable'
        verified: ->
            if Meteor.userId()and Meteor.user().emails[0].verified
                Session.set 'verified', true
            else
                Session.set 'verified', false
            Session.get 'verified'
    )

    Template.control_panel.bookable = ->
        Session.get 'bookable'

    Template.cal.rendered = ->
        $('table#calendar').selectable({filter: 'td'})
        if Session.equals 'bookable', false
            Session.set 'notify', 'Booking is disabled in the current view due to viewing past dates'

    Template.cal.events =
        'click #go-prev': (evt) ->
            evt.preventDefault()
            view = Session.get 'view'
            newView = view.addMonths -1
            Session.set 'view', newView
        'click #go-next': (evt) ->
            evt.preventDefault()
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

    Template.booking_form.book_form = ->
        Session.get 'bookForm'

    Template.booking_form.events =
        'click #booking-submit': (evt, template) ->
            evt.preventDefault()
            for i in template.findAll 'input[type=text]'
                if i.value is ''
                    submitError = template.find 'small'
                    $(submitError).fadeIn(400).delay(1500)
                    $(submitError).fadeOut()
                    i.focus()
                    return false
            dates = []
            $('table#calendar').find('td.ui-selected').each ->
                datetime = $(this).children('time').attr 'datetime'
                dates.push datetime
            contactName = template.find('input[name=contact_name]').value
            contactPhone = template.find('input[name=contact_phone]').value
            projectDesc = template.find('input[name=project_desc]').value
            fileIn = template.find 'input[type=file]'
            file = fileIn.files[0]
            if file
                MeteorFile.read(file, (err, meteorFile) ->
                    Meteor.call "uploadFile", meteorFile, (err) ->
                        if err
                            throw err
                )
            view = Session.get 'view'
            view = view.toString 'MMyy'
            userId = Meteor.userId()
            if Session.equals 'sequencer','hiseq'
                HiseqBookings.insert { user: userId, booking_dates : dates, view: view, contact_name: contactName, contact_phone: contactPhone, project_desc: projectDesc }
            else
                MiseqBookings.insert { user: userId, booking_dates : dates, view: view, contact_name: contactName, contact_phone: contactPhone, project_desc: projectDesc }
            Session.set 'bookForm', false
            Session.set 'notify', 'Booking created'
        'click #booking-cancel': (evt) ->
            evt.preventDefault()
            Session.set 'bookForm', false
            Session.set 'notify', 'Booking was canceled'

    Template.control_panel.events =
        'click #btn-book': (evt) ->
            evt.preventDefault()
            user = Session.get 'user'
            if not user
                Session.set 'notify', 'Please login before making a booking!'
                return false
            if not $('a.seq-select').children('img').hasClass('seq-selected')
                Session.set 'notify', 'Please select a sequencer to book'
                return false
            else if $('table#calendar').find('td.ui-selected.booked').length > 0
                Session.set 'notify', 'You have selected an already booked date(s)'
                return false
            else if $('table#calendar').find('td.ui-selected').length is 0
                message = 'You haven\'t selected any dates to book!'
                Session.set 'notify', message
                return false
            else
                Session.set 'bookForm', true
                bookInFocus = $('#booking-form input:first')
                bookInFocus.focus()
        'click #btn-unbook': (evt) ->
            evt.preventDefault()
            user = Session.get 'user'
            if not user
                Session.set 'notify','Please login before making changes to a booking!'
                return false
            dates = []
            notBooked = ''
            $('table#calendar').find('td.ui-selected').each ->
                if not $(this).hasClass('booked')
                    notBooked = true
                    return false
                else
                    datetime = $(this).children('time').attr 'datetime'
                    dates.push datetime
            if dates.length is 0
                Session.set 'notify','You have not selected a booking to unbook!'
                return false
            if notBooked
                Session.set 'notify','Your selection contains unbooked days, please try again!'
                return false
            view = Session.get 'view'
            view = view.toString 'MMyy'
            if Session.equals 'sequencer','hiseq'
                bookings = HiseqBookings.find({ view: view }).fetch()
            else
                bookings = MiseqBookings.find({ view: view }).fetch()
            unbook = []
            userId = []
            bookings.forEach (booking) ->
                for date in booking.booking_dates
                    if date in dates
                        unbook.push booking._id
                        userId.push booking.user
            for id in unbook
                if id isnt unbook[0]
                    Session.set 'notify', 'You have selected multiple bookings, you can only unbook one booking at a time!'
                    return false
            if userId[0] isnt Meteor.userId()
                    Session.set 'notify','The booking you have selected was booked by another user, please unbook from the same account!', 'highlight', ''
                    return false
            check = confirm ("Are you sure you want to unbook this booking?")
            if check
                if Session.equals 'sequencer', 'hiseq'
                    HiseqBookings.remove(unbook[0])
                else
                    MiseqBookings.remove(unbook[0])
            else
                return false
        'click #btn-info': (evt) ->
            evt.preventDefault()
            selected = $('table#calendar').find('td.ui-selected')
            if not selected
                Session.set 'notify', 'You have not selected a booking!'
                return false
            selectedBooked = false
            for i in selected
                if $(i).hasClass('booked')
                    selectedBooked = true
                    selected = i
                    break
            if selectedBooked is false
                Session.set 'notify', 'You need to select a booking to obtain the booking information!'
                return false
            datetime = $(selected).children('time').attr('datetime')
            view = Session.get 'view'
            view = view.toString 'MMyy'
            if Session.equals 'sequencer', 'hiseq'
                bookings = HiseqBookings.find({view: view}).fetch()
            else
                bookings = MiseqBookings.find({view: view}).fetch()
            bookInfo = {}
            bookings.every (booking) ->
                if datetime in booking.booking_dates
                    bookInfo.id = booking._id
                    bookInfo.contactName = booking.contact_name
                    bookInfo.contactPhone = booking.contact_phone
                    bookInfo.projectDesc = booking.project_desc
                    bookInfo.beginDate = booking.booking_dates[0]
                    bookInfo.endDate = booking.booking_dates.pop()
                    return
            Session.set 'bookInfo', bookInfo
            #            $('.ui-widget-overlay').show()
            #            $('#booking-info').show()
        'click .seq-select': (evt) ->
            evt.preventDefault()
            seq = $( evt.target ).attr('id')
            Session.set 'sequencer', seq
            $('a.seq-select').children('img').removeClass('seq-selected')
            $( evt.target ).addClass('seq-selected')
            message = seq.toUpperCase() + ' selected'
            Session.set 'notify', message
        'click .btn-false': (evt) ->
            action = $(evt.target).text()
            Session.set 'notify', 'Your account is still waiting to be verified, you cannot '+action.toLowerCase()+' until you vefify your email address '

    Template.booking_info.info = ->
        Session.get 'bookInfo'

    Template.booking_info.events =
        'click .btn': (evt) ->
            evt.preventDefault()
            Session.set 'bookInfo', false

    Template.notify.notify = ->
        notify = Session.get 'notify'
        if notify
            Meteor.setTimeout (->
                Session.set 'notify', ''
            ), 5000
        notify

    Template.admin.info = ->
        if Meteor.user() and Meteor.user().admin
            view = Session.get 'view'
            view = view.toString 'MMyy'
            bookings = HiseqBookings.find({view: view}).fetch()
            booked_dates = []
            bookings.forEach (booking) ->
                for date in booking.booking_dates
                    booked_dates.push date
            booked_dates
        else
            false

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
        actual = new Date.today()
        actualMonth = actual.getMonth() + 1
        actualYear = actual.getFullYear()
        if calendar.month < actualMonth and calendar.year <= actualYear or calendar.month >= actualMonth and calendar.year < actualYear
            Session.set 'bookable', false
        else
            Session.set 'bookable', true
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
            bookedText = ''
            bookings.forEach (booking) ->
                for date in booking.booking_dates
                    if date is datetime
                        cssclass+= " booked"
                        bookedText = '<div><small>' + Session.get('sequencer') + ' booking</small></div>'
            cssclass+= ' day'
            td_cell='<td class=\'' + cssclass + '\'><time datetime="' + datetime + '">' + dayNum + '</time>' + bookedText + '</td>'
            out+=td_cell
            if cell >= calendar.firstDayCell and cell <= calendar.lastDayCell
                dayNumThisMonth++
            cell++
            if cell > row_stop
                out+='</tr>'
                row_stop+=7
        calendar.html = out
        calendar

