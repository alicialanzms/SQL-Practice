SELECT 
    a.PatientID,
    p.Name,
    a.AppointmentDate,
    a.Duration,
    ROUND(AVG(a.Duration) OVER (
        PARTITION BY a.PatientID 
        ORDER BY a.AppointmentDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ), 2) AS RollingAvgDuration
FROM 
    Appointments a
JOIN 
    Patients p ON a.PatientID = p.PatientID
ORDER BY 
    a.PatientID,
    a.AppointmentDate;

------------------------------------------------------------

WITH itemranks AS(
    SELECT application_id, line_item_type, amount, updated_at, 
    ROW_NUMBER() OVER(PARTITION BY application_id,line_item_type ORDER BY updated_at ASC) as highest, 
    ROW_NUMBER() OVER(PARTITION BY application_id,line_item_type ORDER BY updated_at DESC) as lowest
    FROM closing_cost_line_item),

valueranks AS(
    SELECT i.application_id, i.line_item_type, 
    ROUND(i.amount,2) AS start,
    ROUND(r.amount,2) AS final,
    ROUND(r.amount/NULLIF(i.amount,0),2) AS factor
    FROM itemranks i JOIN itemranks r 
    ON i.application_id = r.application_id
    AND i.line_item_type = r.line_item_type
    WHERE i.highest =1 AND r.lowest=1),
    
funded AS(
    SELECT *
    FROM valueranks vr 
    JOIN application a ON vr.application_id = a.application_id
    WHERE a.funded_at IS NOT NULL AND ROUND(vr.final/NULLIF(vr.start,0),2) > 15)
    
SELECT application_id, line_item_type AS line_item_name, start AS first_value, final AS last_value, factor
FROM funded
ORDER BY factor DESC
LIMIT 1;
