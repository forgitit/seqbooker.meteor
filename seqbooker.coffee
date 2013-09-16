if Meteor.isClient

    Bookings = new Meteor.Collection 'Bookings'

    defaultView = new Date.today() 
    Session.setDefault 'view', defaultView

    Template.cal.calendar = ->
        dateObj = Session.get 'view'
        genCal dateObj

    Template.cal.events = 
        'click a.prev-month': (evt) ->
            evt.preventDefault
            view = Session.get 'view'
            newView = view.addMonths -1
            Session.set 'view', newView
        'click a.next-month': (evt) ->
            evt.preventDefault
            view = Session.get 'view'
            newView = view.addMonths 1
            Session.set 'view', newView
        'click table td': (evt) ->
            console.log evt.target
            $ ->
                console.log $(evt.target).text()
            

    genCal = (dateObj) ->
        month = dateObj.toString 'MMMM'
        firstDayCell = dateObj.moveToFirstDayOfMonth().getDay()  
        todayDate= new Date().getDate() - 1
        console.log firstDayCell
        lastDayCell = dateObj.moveToLastDayOfMonth().getDate() + firstDayCell - 1
        console.log lastDayCell
        daysInMonth = dateObj.getDaysInMonth()
        if daysInMonth + firstDayCell > 35
            cell_length = 42 
        else
            cell_length = 35
        out =
        '<h3 class="month">'+month+'</h3><table class=\'table table-bordered\'><tr><th>Sun</th><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th>Sat</th></tr><tr>'
        cell = 0
        row_stop = 6
        dayDate = 1
        while cell < cell_length
            cssclass = ''
            if cell is todayDate
                cssclass+=" today"
            if cell >= firstDayCell and cell <= lastDayCell
                cssclass+=' day'
                td_cell='<td class=\'' + cssclass + '\'>' + dayDate + '</td>'
                out+=td_cell
                dayDate++
            else 
                if cell < firstDayCell
                    cssclass+=' past'
                else
                    cssclass+=' future'
                cssclass+=' noday'
                td_cell='<td class=\'' + cssclass + '\'></td>'
                out+=td_cell
            cell++
            if cell > row_stop
                out+='</tr>'
                row_stop+=7
        out+='</table>'
        out
