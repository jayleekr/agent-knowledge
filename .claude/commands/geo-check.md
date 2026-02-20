# geo-check

Run geo score analysis on a file.

## Usage

```
/geo-check <file_path>
```

`$ARGUMENTS` = file path to analyze

## Steps

1. Run the geo analyzer on the provided file:
   ```bash
   ops/analyze/geo-check.sh $ARGUMENTS
   ```

2. Display results:
   - File analyzed
   - Total entries with geo scores
   - Average, min, max scores
   - Distribution breakdown (0-59 / 60-74 / 75-89 / 90-100)

3. Highlight:
   - Average below 70: warning
   - Average below 60: critical
   - Any score below 50: flag individual entries

## Example

```
/geo-check metrics/geo-trends.json
/geo-check ~/CodeWorkspace/hypeproof/scripts/submissions.json
```
