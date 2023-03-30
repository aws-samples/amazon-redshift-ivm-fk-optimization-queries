# Description

This repository contains the Materialized Views and the update policy used
during the evaluation of the method described in the publication: "Foreign Keys
Open the Door for Faster Incremental View Maintenance" which got accepted in
SIGMOD 2023 conference. More specifically, this repository contains the SQL
scripts used during the evaluation of each Materialized View. Each script is
structured as follows:

  1. Choose the inserted/deleted tuples.
  2. Create a copy of the MV base tables.
  4. Load the copied tables with data without including the tuples that are
     going to be inserted.
  5. Create the MV.
  6. Insert/Delete the chosen tuples.
  7. Refresh the materialized view.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This repository is licensed under the MIT-0 License. See the LICENSE file.

