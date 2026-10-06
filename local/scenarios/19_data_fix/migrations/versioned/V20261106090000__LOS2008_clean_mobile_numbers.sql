-- Ticket : LOS2008
-- Purpose: one-time data fix - remove spaces and dashes from mobile numbers.

UPDATE customer
   SET mobile_no = REPLACE(REPLACE(mobile_no, ' ', ''), '-', '')
 WHERE mobile_no LIKE '% %' OR mobile_no LIKE '%-%';
