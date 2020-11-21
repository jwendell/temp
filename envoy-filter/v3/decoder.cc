#include "extensions/filters/http/jwendell/decoder.h"

namespace Envoy {
namespace Extensions {
namespace HttpFilters {
namespace JWendell {

Http::FilterHeadersStatus SampleDecoderFilter::decodeHeaders(Http::RequestHeaderMap& headers, bool) {
  headers.addCopy(Http::LowerCaseString(key_), val_);

  auto tracing_config = decoder_callbacks_->tracingConfig();
  if (tracing_config != nullptr) {
    std::cout << "TRACING VERBOSE = " << tracing_config->verbose() << std::endl;

    std::string name = "UNKNOWN";
    if (tracing_config->operationName() == Tracing::OperationName::Ingress)
      name = "INGRESS";
    else if (tracing_config->operationName() == Tracing::OperationName::Egress)
      name = "EGRESS";
    std::cout << "TRACING OPERATION = " << name << std::endl;
  } else
    std::cout << "TRACING IS NULL!" << std::endl;

  return Http::FilterHeadersStatus::Continue;
}

Http::FilterDataStatus SampleDecoderFilter::decodeData(Buffer::Instance&, bool) {
  return Http::FilterDataStatus::Continue;
}

void SampleDecoderFilter::setDecoderFilterCallbacks(Http::StreamDecoderFilterCallbacks& callbacks) {
  decoder_callbacks_ = &callbacks;
}

} // namespace JWendell
} // namespace HttpFilters
} // namespace Extensions
} // namespace Envoy
