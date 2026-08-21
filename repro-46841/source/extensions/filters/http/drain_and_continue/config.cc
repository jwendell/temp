#include <string>

#include "envoy/http/filter.h"
#include "envoy/registry/registry.h"
#include "envoy/server/filter_config.h"

#include "source/common/protobuf/protobuf.h"
#include "source/extensions/filters/http/common/pass_through_filter.h"

namespace Envoy {
namespace Extensions {
namespace HttpFilters {
namespace DrainAndContinue {

// LOCAL-ONLY REPRODUCER FILTER -- NOT FOR UPSTREAM.
//
// Deterministic trigger for the filter-manager body-frame-loss bug described in
// https://github.com/envoyproxy/envoy/issues/46841
//
// The filter iterates on headers, then on the first NON-final body frame drains that
// frame into the filter-manager buffer via addDecodedData() and returns Continue.
// Because the filter is already iterating, this exercises the
// commonHandleAfterDataCallback() Continue path where the just-buffered frame must be
// forwarded down the chain rather than the now-empty frame. Subsequent frames pass
// through untouched, so the frame carrying end_stream is never dropped and the request
// still completes normally -- the body just arrives truncated (exactly the real bug).
//
// It deliberately only touches the request (decode) path so responses stay intact and
// the echo upstream's JSON remains parseable regardless of the guard.
//
// With the runtime guard
// `envoy.reloadable_features.filter_manager_forward_added_data_on_continue`
// OFF, the drained frame is lost. With it ON (default), the body is intact.
class DrainAndContinueFilter : public Http::PassThroughFilter {
public:
  Http::FilterDataStatus decodeData(Buffer::Instance& data, bool end_stream) override {
    if (!drained_a_frame_ && !end_stream && data.length() > 0) {
      drained_a_frame_ = true;
      decoder_callbacks_->addDecodedData(data, false);
    }
    return Http::FilterDataStatus::Continue;
  }

private:
  bool drained_a_frame_{false};
};

// Uses google.protobuf.Struct as the (ignored) config type so no new API proto is
// needed for this local reproducer. The config is never inspected or validated.
// Configure via:
//   typed_config:
//     "@type": type.googleapis.com/google.protobuf.Struct
class DrainAndContinueFilterConfig : public Server::Configuration::NamedHttpFilterConfigFactory {
public:
  absl::StatusOr<Http::FilterFactoryCb>
  createFilterFactoryFromProto(const Protobuf::Message&, const std::string&,
                               Server::Configuration::FactoryContext&) override {
    return [](Http::FilterChainFactoryCallbacks& callbacks) -> void {
      callbacks.addStreamFilter(std::make_shared<DrainAndContinueFilter>());
    };
  }

  ProtobufTypes::MessagePtr createEmptyConfigProto() override {
    return ProtobufTypes::MessagePtr{new Protobuf::Struct()};
  }

  // NOTE: configTypes() is intentionally NOT overridden. The default derives the config type
  // (google.protobuf.Struct) from createEmptyConfigProto(), which is how HTTP filters are resolved
  // by type URL. Overriding it to {} would make this filter unresolvable.

  std::string name() const override { return "envoy.filters.http.drain_and_continue"; }
};

// perform static registration
LEGACY_REGISTER_FACTORY(DrainAndContinueFilterConfig,
                        Server::Configuration::NamedHttpFilterConfigFactory,
                        "envoy.drain_and_continue");

} // namespace DrainAndContinue
} // namespace HttpFilters
} // namespace Extensions
} // namespace Envoy
