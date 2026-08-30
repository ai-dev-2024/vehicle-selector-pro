import React from "react";
import {
  AbsoluteFill, Audio, Img, Sequence, interpolate, staticFile, useCurrentFrame, Easing,
} from "remotion";
import type { Scene } from "./scenes";

const FPS = 30;
const PAPER = "#E8EBEF";
const INK = "#0B1016";
const RAIL = "#FF4A00";

function KenBurns({ src, duration }: { src: string; duration: number }) {
  const frame = useCurrentFrame();
  const scale = interpolate(frame, [0, duration * FPS], [1.0, 1.12], {
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.ease),
  });
  return (
    <AbsoluteFill style={{ backgroundColor: INK }}>
      <div style={{ transform: `scale(${scale})`, transformOrigin: "50% 42%", width: "100%", height: "100%" }}>
        <Img src={src} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
      <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(11,16,22,0.20) 0%, rgba(11,16,22,0.04) 40%, rgba(11,16,22,0.60) 100%)" }} />
    </AbsoluteFill>
  );
}

function CaptionPlate({ caption, accent }: { caption: string | null; accent: string }) {
  const frame = useCurrentFrame();
  if (!caption) return null;
  const y = interpolate(frame, [0, 18], [-44, 0], { extrapolateRight: "clamp", extrapolateLeft: "clamp", easing: Easing.out(Easing.cubic) });
  const o = interpolate(frame, [0, 18], [0, 1], { extrapolateRight: "clamp", extrapolateLeft: "clamp" });
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", pointerEvents: "none" }}>
      <div
        style={{
          position: "absolute",
          bottom: 128,
          background: "rgba(237,239,242,0.94)",
          color: INK,
          fontFamily: "Archivo, Segoe UI, sans-serif",
          fontWeight: 800,
          fontSize: 40,
          letterSpacing: ".02em",
          padding: "16px 36px 16px 30px",
          borderLeft: `10px solid ${accent}`,
          transform: `translateY(${y}px)`,
          opacity: o,
          boxShadow: "0 20px 60px rgba(0,0,0,0.38)",
        }}
      >
        {caption}
      </div>
    </AbsoluteFill>
  );
}

function TopRail() {
  return (
    <AbsoluteFill style={{ zIndex: 20, pointerEvents: "none" }}>
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 10, background: RAIL }} />
      <div style={{ position: "absolute", top: 30, left: 32, color: "#fff", fontFamily: "Archivo, Segoe UI, sans-serif", fontWeight: 700, fontSize: 20, letterSpacing: ".12em" }}>
        <span style={{ color: RAIL }}>VEHICLE&nbsp;SELECTOR&nbsp;PRO</span>
        <span style={{ color: "rgba(255,255,255,0.7)", marginLeft: 16 }}>/</span>
      </div>
      <div style={{ position: "absolute", top: 34, right: 34, color: "rgba(255,255,255,0.78)", fontFamily: "Archivo, Segoe UI, sans-serif", fontWeight: 600, fontSize: 15, letterSpacing: ".16em" }}>APPLICATION&nbsp;DEMO&nbsp;·&nbsp;2026</div>
    </AbsoluteFill>
  );
}

function TitleCard({ title, sub }: { title: string; sub: string }) {
  const frame = useCurrentFrame();
  const o = interpolate(frame, [0, 24], [0, 1], { extrapolateRight: "clamp", extrapolateLeft: "clamp" });
  return (
    <AbsoluteFill style={{
      background: "repeating-linear-gradient(0deg, transparent 0 48px, rgba(11,16,22,0.05) 48px 50px), repeating-linear-gradient(90deg, transparent 0 48px, rgba(11,16,22,0.05) 48px 50px), linear-gradient(180deg,#EDEFF2,#DDE3EA)",
      opacity: o,
    }}>
      <div style={{ position: "absolute", left: 76, top: 130, width: 120, height: 9, backgroundColor: RAIL }} />
      <div style={{ position: "absolute", left: 74, top: 180, color: INK, fontFamily: "Archivo, Segoe UI, sans-serif", fontWeight: 800, fontSize: 96, lineHeight: 1.02, letterSpacing: "-.02em", maxWidth: 1100 }}>{title}</div>
      <div style={{ position: "absolute", left: 78, top: 400, color: "rgba(11,16,22,0.72)", fontFamily: "Archivo, Segoe UI, sans-serif", fontWeight: 500, fontSize: 30, maxWidth: 900 }}>{sub}</div>
      <div style={{ position: "absolute", left: 80, bottom: 120, color: INK, fontFamily: "Archivo, Segoe UI, sans-serif", fontWeight: 600, fontSize: 18, letterSpacing: ".16em" }}>
        <span style={{ color: RAIL }}>vehicle-selector-pro</span>&nbsp;·&nbsp;SHOPIFY&nbsp;APPLICATION&nbsp;DEMO
      </div>
    </AbsoluteFill>
  );
}

export const DemoVideo: React.FC<{ scenes: Scene[]; title: string; sub: string }> = ({ scenes, title, sub }) => {
  let cursor = 0;
  const children = scenes.map((s) => {
    const start = cursor;
    const dur = Math.round(s.dur * FPS);
    cursor += dur;
    const isTitle = s.id === "title" || s.id === "outro";
    return (
      <Sequence key={s.id} from={start} durationInFrames={dur} name={s.id}>
        {isTitle ? (
          <TitleCard title={title} sub={sub} />
        ) : (
          <KenBurns src={staticFile(s.frame!)} duration={s.dur} />
        )}
        {!isTitle && <CaptionPlate caption={s.caption} accent={s.accent} />}
        <TopRail />
        <Audio src={staticFile(s.audio)} />
      </Sequence>
    );
  });
  const totalFrames = cursor;
  return (
    <AbsoluteFill style={{ backgroundColor: PAPER, fontFamily: "Archivo, Segoe UI, sans-serif" }}>
      {children}
    </AbsoluteFill>
  );
};
