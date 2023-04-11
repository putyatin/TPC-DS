SELECT split_part(description, '.', 2) as table_name, sum(tuples) as tuples, sum(extract('epoch' from duration)) AS seconds 
FROM tpcds_reports.report
WHERE tuples > 0  and step='load'
GROUP BY split_part(description, '.', 2)
ORDER BY 1;
