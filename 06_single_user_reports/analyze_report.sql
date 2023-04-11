SELECT split_part(description, '.', 1) as schema_name, extract('epoch' from duration) AS seconds 
FROM tpcds_reports.report 
WHERE step='load' and tuples = 0
ORDER BY 1;
