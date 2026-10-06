# Repeatable files (R files)

One file per database code object. File name decides the run order:

```
R__<NN>_<type>_<object_name>.sql
```

| NN | Object type        | Example file name                          |
|----|--------------------|--------------------------------------------|
| 05 | synonyms           | `R__05_synonym_customer_api.sql`           |
| 10 | package specs      | `R__10_package_spec_loan_pkg.sql`      |
| 20 | functions, procedures | `R__20_procedure_add_customer.sql` |
| 30 | views              | `R__30_view_v_loan_summary.sql`          |
| 40 | package bodies     | `R__40_package_body_loan_pkg.sql`      |
| 50 | triggers           | `R__50_trigger_customer_bi.sql`            |
| 60 | grants             | `R__60_grants_app_reader.sql`                |

You may create sub-folders to make browsing easier; folders do **not** change the order.
