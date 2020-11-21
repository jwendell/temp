#pragma once

#include <string>
#include "extensions/filters/http/common/pass_through_filter.h"
#include "source/extensions/filters/http/jwendell/decoder.pb.h"
#include "source/extensions/filters/http/jwendell/decoder.pb.validate.h"

namespace Envoy {
namespace Extensions {
namespace HttpFilters {
namespace JWendell {

class SampleDecoderFilter : public Http::PassThroughDecoderFilter {
public:
  SampleDecoderFilter(const envoy::extensions::filters::http::jwendell::v3::Decoder& proto_config)
      : key_(proto_config.header_key()),
        val_(proto_config.header_value()) {};

  Http::FilterHeadersStatus decodeHeaders(Http::RequestHeaderMap&, bool) override;
  Http::FilterDataStatus decodeData(Buffer::Instance&, bool) override;
  void setDecoderFilterCallbacks(Http::StreamDecoderFilterCallbacks&) override;

private:
  Http::StreamDecoderFilterCallbacks* decoder_callbacks_;
  const std::string key_;
  const std::string val_;
};

} // namespace JWendell
} // namespace HttpFilters
} // namespace Extensions
} // namespace Envoy
