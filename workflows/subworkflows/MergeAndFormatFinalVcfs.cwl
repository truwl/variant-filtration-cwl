#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: MultipleInputFeatureRequirement
  - $import: ../../tools/schemas.cwl

inputs:
  input_snp_vcf: File
  input_indel_vcf: File
  full_reference_sequence_dictionary: File
  main_reference_sequence_dictionary: File
  vcf_metadata: "../../tools/schemas.cwl#vcf_metadata_record"
  uuid: string

outputs:
  processed_vcf:
    type: File
    outputSource: vcf_convert/output_file

steps:
  merge_vcfs:
    run: ../../tools/PicardMergeVcfs.cwl
    in:
      input_vcf: [ input_snp_vcf, input_indel_vcf ] 
      sequence_dictionary: full_reference_sequence_dictionary
      output_filename:
        source: uuid
        valueFrom: $(self + '.merged.vcf.gz')
    out: [ output_vcf_file ]

  update_dictionary:
    run: ../../tools/PicardUpdateSequenceDictionary.cwl
    in:
      input_vcf: merge_vcfs/output_vcf_file
      sequence_dictionary: main_reference_sequence_dictionary 
      output_filename:
        source: uuid
        valueFrom: $(self + '.merged.seqdict.vcf')
    out: [ output_file ]

  contig_filter:
    run: ../../tools/ContigFilter.cwl
    in:
      input_vcf: update_dictionary/output_file
      output_vcf:
        source: uuid
        valueFrom: $(self + '.merged.seqdict.contigfilter.vcf')
    out: [ output_vcf_file ]

  format_header:
    run: ../../tools/FormatVcfHeader.cwl
    in:
      input_vcf: contig_filter/output_vcf_file
      output_vcf:
        source: uuid
        valueFrom: $(self + '.merged.seqdict.contigfilter.vcf')
      reference_name: 
        source: vcf_metadata
        valueFrom: $(self.reference_name)
      patient_barcode: 
        source: vcf_metadata
        valueFrom: $(self.patient_barcode)
      case_id:
        source: vcf_metadata
        valueFrom: $(self.case_id)
      tumor_barcode:
        source: vcf_metadata
        valueFrom: $(self.tumor_barcode)
      tumor_aliquot_uuid:
        source: vcf_metadata
        valueFrom: $(self.tumor_aliquot_uuid)
      tumor_bam_uuid:
        source: vcf_metadata
        valueFrom: $(self.tumor_bam_uuid)
      normal_barcode:
        source: vcf_metadata
        valueFrom: $(self.normal_barcode)
      normal_aliquot_uuid:
        source: vcf_metadata
        valueFrom: $(self.normal_aliquot_uuid)
      normal_bam_uuid:
        source: vcf_metadata
        valueFrom: $(self.normal_bam_uuid)
      caller_workflow_id:
        source: vcf_metadata
        valueFrom: $(self.caller_workflow_id)
      caller_workflow_name:
        source: vcf_metadata
        valueFrom: $(self.caller_workflow_name)
      caller_workflow_description:
        source: vcf_metadata
        valueFrom: $(self.caller_workflow_description)
      caller_workflow_version:
        source: vcf_metadata
        valueFrom: $(self.caller_workflow_version)
      annotation_workflow_id:
        source: vcf_metadata
        valueFrom: $(self.annotation_workflow_id)
      annotation_workflow_name:
        source: vcf_metadata
        valueFrom: $(self.annotation_workflow_name)
      annotation_workflow_description:
        source: vcf_metadata
        valueFrom: $(self.annotation_workflow_description)
      annotation_workflow_version:
        source: vcf_metadata
        valueFrom: $(self.annotation_workflow_version)
    out: [ output_vcf_file ]

  vcf_convert:
    run: ../../tools/PicardVcfFormatConverter.cwl
    in:
      input_vcf: format_header/output_vcf_file
      output_filename:
        source: uuid
        valueFrom: $(self + '.processed.vcf.gz')
    out: [ output_file ]
