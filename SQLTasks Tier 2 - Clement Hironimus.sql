/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS */
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT
    name AS non_free_facility_name_for_member,
    membercost AS member_cost_usd -- ASSUMING the currency is in USD based from Question 5
FROM main.Facilities
WHERE membercost > 0 -- To get facilities that charge cost to members
ORDER BY member_cost_usd DESC -- [Extra] To sort from highest member cost
;

/* Q2: How many facilities do not charge a fee to members? */

SELECT
    name AS free_facility_name_for_member,
    membercost AS member_cost_usd
FROM main.Facilities
WHERE membercost <= 0 -- To get facilities that do not charge cost to members
;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT
    facid,
    name AS facility_name,
    membercost AS member_cost_usd,
    monthlymaintenance AS monthly_maintenance_usd,
    membercost / monthlymaintenance AS member_fee_to_monthly_maintenance_pct

FROM main.Facilities
WHERE
    membercost > 0 -- To get facilities that charge fees to members
    AND membercost / monthlymaintenance < 0.2 -- To get facilities where the fee is <20% of facility's monthly maintenance cost
ORDER BY membercost / monthlymaintenance DESC -- [Extra] To sort based on highest % of facility's member cost to its monthly maintenance cost
;


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT *
FROM main.Facilities
WHERE
    facid IN (1, 5) -- 1 = "Tennis Court 2"; 5 = "Massage Room 2"
;

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT
    name AS facility_name,
    monthlymaintenance AS monthly_maintenance_usd,
    IIF(monthlymaintenance > 100, 'expensive', 'cheap') AS facility_maintenance_expensive_category
FROM main.Facilities
ORDER BY monthlymaintenance DESC -- [Extra] To sort based on highest facility's maintenance cost
;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

WITH cte AS (

    SELECT
        *,
        DENSE_RANK() OVER(ORDER BY joindate DESC) AS member_order_of_joining_from_latest
    FROM main.Members

)
SELECT
    (firstname || ' ' || surname) AS most_recently_joined_member_first_last_name,
    joindate AS memnber_join_date_time
FROM cte
WHERE member_order_of_joining_from_latest = 1
;


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT DISTINCT
    (members.firstname || ' ' || members.surname) AS member_first_last_name,
    facilities.name AS facility_name

FROM main.Facilities AS facilities

    -- [1:MANY] Get list of bookings associated with the facilities
    INNER JOIN main.Bookings AS bookings
        ON facilities.facid = bookings.facid
            AND bookings.memid != 0 -- To exclude bookings from non-members (memid 0 = GUEST GUEST)

    -- [many:1] Get list of members who booked the facilities
    LEFT JOIN main.Members AS members
        ON bookings.memid = members.memid

WHERE
    name LIKE '%tennis court%' -- Starts with "Tennis Court" facilities (because we don't need other facilities data)

ORDER BY 2
;


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT
    STRFTIME('%Y-%m-%d', starttime) AS booking_date,
    facilities.name AS facility_name,
    (members.firstname || ' ' || members.surname) AS member_first_last_name,

    -- To get the "per-half-hour" cost and how many "slots" booked
        -- The "IIF" is to differentiate between Guest vs Member Cost (Guest always has ID = 0)
    IIF(bookings.memid = 0, facilities.guestcost, facilities.membercost) AS usd_cost_per_half_hour_slot,
    bookings.slots,

    -- Total Cost (= Member/Guest Cost per Slot x Slots Booked)
    IIF(bookings.memid = 0, facilities.guestcost, facilities.membercost) * bookings.slots AS usd_total_booking_cost

FROM main.Bookings AS bookings

    -- [many:1] Facility
    LEFT JOIN main.Facilities AS facilities
        ON bookings.facid = facilities.facid

    -- [many:1] Member or Guest
    LEFT JOIN main.Members AS members
        ON bookings.memid = members.memid
WHERE
    STRFTIME('%Y-%m-%d', starttime) = '2012-09-14' -- To filter for bookings on the day of 2012-09-14
    AND IIF(bookings.memid = 0, facilities.guestcost, facilities.membercost) * bookings.slots > 30 -- To get where the booking's total cost > $30
;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
WITH cte AS (

    SELECT
        STRFTIME('%Y-%m-%d', starttime) AS booking_date,
        facilities.name AS facility_name,
        (members.firstname || ' ' || members.surname) AS member_first_last_name,

        -- To get the "per-half-hour" cost and how many "slots" booked
            -- The "IIF" is to differentiate between Guest vs Member Cost (Guest always has ID = 0)
        IIF(bookings.memid = 0, facilities.guestcost, facilities.membercost) AS usd_cost_per_half_hour_slot,
        bookings.slots,

        -- Total Cost (= Member/Guest Cost per Slot x Slots Booked)
        IIF(bookings.memid = 0, facilities.guestcost, facilities.membercost) * bookings.slots AS usd_total_booking_cost

    FROM main.Bookings AS bookings

        -- [many:1] Facility
        LEFT JOIN main.Facilities AS facilities
            ON bookings.facid = facilities.facid

        -- [many:1] Member or Guest
        LEFT JOIN main.Members AS members
            ON bookings.memid = members.memid
    WHERE
        STRFTIME('%Y-%m-%d', starttime) = '2012-09-14' -- To filter for bookings on the day of 2012-09-14
)
SELECT *
FROM cte
WHERE usd_total_booking_cost > 30 -- To get where the booking's total cost > $30
ORDER BY usd_total_booking_cost DESC
;


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

-- NOTE: Answers are also available in Jupyter Notebook File

-- ASSUMPTION: This doesn't include facility's "initialoutlay" and "monthlymaintenance" costs when calculating revenue
WITH cte AS (

    SELECT
        facilities.name AS facility_name,

        -- Since no start/end date is specified in question, we'll use the earliest & latest booking's "start/end date"
        STRFTIME('%Y-%m-%d', MIN(bookings.starttime) OVER()) AS reporting_start_date,
        STRFTIME('%Y-%m-%d', MAX(bookings.starttime) OVER()) AS reporting_end_date,

        -- To get the "per-half-hour" cost and how many "slots" booked
                -- The "IIF" is to differentiate between Guest vs Member Cost (Guest always has ID = 0)
        IIF(bookings.memid = 0, facilities.guestcost, facilities.membercost) AS usd_revenue_per_half_hour_slot,
        bookings.slots AS number_of_slots_booked

    FROM main.Bookings AS bookings

        -- [many:1] Facility
        LEFT JOIN main.Facilities AS facilities
            ON bookings.facid = facilities.facid

        -- [many:1] Member or Guest
        LEFT JOIN main.Members AS members
            ON bookings.memid = members.memid

)
SELECT
    facility_name,
    reporting_start_date,
    reporting_end_date,
    SUM(usd_revenue_per_half_hour_slot * number_of_slots_booked) AS usd_total_revenue

FROM cte

GROUP BY
    facility_name,
    reporting_start_date,
    reporting_end_date
HAVING usd_total_revenue < 1000
;

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT

    -- Member
    members.memid,
    members.surname AS member_surname,
    members.firstname AS memnber_firstname,

    -- Referrer
    member_referrer.memid AS member_referrer_memid,
    (member_referrer.firstname || ' ' || member_referrer.surname) AS member_referrer_first_last_name

FROM main.Members AS members

    -- Get Member who Referred
    LEFT JOIN main.Members AS member_referrer
        ON members.recommendedby = member_referrer.memid

WHERE
    (members.recommendedby IS NOT NULL AND members.recommendedby != '') -- To get members who got referred

ORDER BY
    members.surname,
    members.firstname
;

/* Q12: Find the facilities with their usage by member, but not guests */
SELECT
    facilities.name AS facility_name,

    -- Since Question didn't specify timeframe, assuming it's from earliest & latest booking date
    STRFTIME('%Y-%m-%d', MIN(bookings.starttime)) AS reporting_start_date,
    STRFTIME('%Y-%m-%d', MAX(bookings.starttime)) AS reporting_end_date,

    SUM(bookings.slots * 0.5) AS facility_usage_total_hours_by_members

FROM main.Bookings AS bookings

    -- [many:1] Facility
    LEFT JOIN main.Facilities AS facilities
        ON bookings.facid = facilities.facid
WHERE
    memid != 0 -- To filter out Guest bookings (memid = 0)

GROUP BY
    facilities.name

ORDER BY
    facility_usage_total_hours_by_members DESC

;

/* Q13: Find the facilities usage by month, but not guests */

-- ASSUMPTION: Total hours of usage across all facilities
SELECT

    -- Since Question didn't specify timeframe, assuming it's from earliest & latest booking date
    STRFTIME('%m-%Y', bookings.starttime) AS facility_usage_month_year,

    SUM(bookings.slots * 0.5) AS total_hours_usage_by_members

FROM main.Bookings AS bookings

    -- [many:1] Facility
    LEFT JOIN main.Facilities AS facilities
        ON bookings.facid = facilities.facid
WHERE
    memid != 0 -- To filter out Guest bookings (memid = 0)

GROUP BY
    STRFTIME('%m-%Y', bookings.starttime)

ORDER BY
    facility_usage_month_year
;



