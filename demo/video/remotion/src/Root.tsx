import React from "react";
import { Composition } from "remotion";
import { DemoVideo } from "./DemoVideo";
import { MERCHANT, SHOPPER } from "./scenes";

const fps = 30;
const W = 1920;
const H = 1080;
const merchantDur = Math.round(MERCHANT.reduce((a, s) => a + s.dur, 0) * fps);
const shopperDur = Math.round(SHOPPER.reduce((a, s) => a + s.dur, 0) * fps);

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="MerchantDemo"
        component={DemoVideo}
        durationInFrames={merchantDur}
        fps={fps}
        width={W}
        height={H}
        defaultProps={{
          scenes: MERCHANT,
          title: "Merchant Command Center",
          sub: "Fitment management for the automotive store — catalog coverage, fitment rules, imports, and GraphQL sync.",
        }}
      />
      <Composition
        id="ShopperDemo"
        component={DemoVideo}
        durationInFrames={shopperDur}
        fps={fps}
        width={W}
        height={H}
        defaultProps={{
          scenes: SHOPPER,
          title: "The Shopper Experience",
          sub: "From vehicle selector to guaranteed-fit checkout — the parts path built for the modern automotive buyer.",
        }}
      />
    </>
  );
};
