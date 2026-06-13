# Publication Corpus Review Schema

Default location: adapt this into `working/YYYY-MM-DD-publication-corpus-schema-<topic>.md`.

Use this template for article-level, paper-level, report-level, or publication-level corpus reviews. Prune fields that are not needed, but keep extraction status and review-status fields so automated labels do not look final.

## Corpus Metadata

- Corpus title:
- Review aim:
- Date created:
- Corpus sources:
- Inclusion criteria:
- Exclusion criteria:
- Retrieval manifest:
- Raw source location:
- Coding status:

## Publication Identity Fields

- `item_id`
- `doi`
- `pmid`
- `url`
- `title`
- `subtitle`
- `publication_type`
- `venue`
- `publisher`
- `volume`
- `issue`
- `pages`
- `publication_date`
- `online_publication_date`
- `authors`
- `corresponding_author`
- `affiliations`
- `abstract`
- `keywords`
- `source_route`
- `local_source_path`

## Source And Access Fields

- `metadata_source`
- `full_text_status`
- `raw_file_status`
- `access_status`
- `retrieval_date`
- `content_type`
- `byte_size`
- `checksum`
- `license_or_reuse_notes`
- `access_notes`

## Review Classification Fields

- `corpus_inclusion_status`: include, exclude, duplicate, uncertain
- `screening_category`
- `publication_category`
- `content_type_primary`
- `content_type_secondary`
- `topic_primary`
- `topic_secondary`
- `domain_primary`
- `domain_secondary`
- `setting`
- `population`
- `geography`
- `jurisdiction`

## Methods And Evidence Fields

- `study_design`
- `data_source_type`
- `data_modality`
- `sample_size`
- `intervention_or_exposure`
- `comparator`
- `outcomes`
- `metrics`
- `validation_level`
- `implementation_maturity`
- `evidence_maturity`
- `limitations_reported`

## Technology Or Intervention Fields

- `system_or_tool_name`
- `task_type`
- `method_family`
- `model_or_algorithm_type`
- `human_role`
- `workflow_stage`
- `integration_context`
- `deployment_status`
- `monitoring_or_feedback`

## Equity, Safety, Governance, And Reproducibility Fields

- `equity_or_bias_focus`
- `demographic_reporting`
- `representativeness_discussed`
- `safety_risks_discussed`
- `privacy_security_discussed`
- `regulatory_discussed`
- `governance_discussed`
- `code_available`
- `data_available`
- `protocol_or_registration_available`
- `reproducibility_notes`

## Extraction And Coding Status Fields

- `extraction_route`
- `extraction_date`
- `coding_status`: unstarted, automated draft, human reviewed, resolved
- `needs_manual_review`: yes, no
- `coding_confidence`: high, medium, low
- `coding_notes`
- `reviewer`
- `last_updated`

## Pilot Coding Rule

Before coding a whole corpus, code a small stratified sample and review whether:

- the schema is too granular
- required metadata are available
- raw files add value beyond metadata pages
- geography and affiliation fields need manual review
- automated labels need simpler categories
- extraction status is clear enough to resume later
