import std.stdio, std.path;
import bin.gff3_benchmark,
       bin.gff3_count_features,
       bin.gff3_ffetch,
       bin.gff3_filter,
       bin.gff3_select,
       bin.gff3_sort,
       bin.gff3_to_gtf,
       bin.gff3_to_json,
       bin.gff3_validate,
       bin.gtf_to_gff3;

int main(string[] args) {
  string exec_filename = baseName(args[0]);
  args[0] = exec_filename;
  switch(exec_filename) {
    case "gff3-benchmark":
    case "gtf-benchmark":
      return gff3_benchmark(args);
      break;
    case "gff3-count-features":
      return gff3_count_features(args);
      break;
    case "gff3-ffetch":
      return gff3_ffetch(args);
      break;
    case "gff3-filter":
    case "gtf-filter":
      return gff3_filter(args);
      break;
    case "gff3-select":
    case "gtf-select":
      return gff3_select(args);
      break;
    case "gff3-sort":
      return gff3_sort(args);
      break;
    case "gff3-to-gtf":
      return gff3_to_gtf(args);
      break;
    case "gff3-to-json":
    case "gtf-to-json":
      return gff3_to_json(args);
      break;
    case "gff3-validate":
      return gff3_validate(args);
      break;
    case "gtf-to-gff3":
      return gtf_to_gff3(args);
      break;
    default:
      return gff3_validate(args);
      break;
  }

  return -1;
}

