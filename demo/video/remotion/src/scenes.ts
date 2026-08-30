// Scene schedules for both demo videos.
// `dur` = total scene duration in seconds (speech + graceful breathing room).
// `frame` = background screenshot (null => pure title card, drawn in code).
// `audio` = narration clip path from /public.
// `accent` = torch-orange tag / rail accent.

export type Scene = {
  id: string;
  frame: string | null;
  caption: string | null;
  audio: string;
  dur: number;
  accent: string;
};

export const MERCHANT: Scene[] = [
  { id: "title", frame: null, caption: null, audio: "audio/merchant/title.mp3", dur: 14.0, accent: "#FF4A00" },
  { id: "dashboard", frame: "frames/admin_overview.png", caption: "Catalog at a glance", audio: "audio/merchant/dashboard.mp3", dur: 16.5, accent: "#FF4A00" },
  { id: "matrix", frame: "frames/admin_matrix.png", caption: "Every fitment, one rule", audio: "audio/merchant/matrix.mp3", dur: 19.0, accent: "#FF4A00" },
  { id: "library", frame: "frames/admin_library.png", caption: "The YMMTE database", audio: "audio/merchant/library.mp3", dur: 18.0, accent: "#FF4A00" },
  { id: "settings", frame: "frames/admin_settings.png", caption: "Brand it to match", audio: "audio/merchant/settings.mp3", dur: 16.5, accent: "#FF4A00" },
  { id: "imports", frame: "frames/admin_imports.png", caption: "Import at scale", audio: "audio/merchant/imports.mp3", dur: 14.0, accent: "#FF4A00" },
  { id: "sync", frame: "frames/admin_sync.png", caption: "Sync, proven", audio: "audio/merchant/sync.mp3", dur: 17.0, accent: "#FF4A00" },
  { id: "outro", frame: null, caption: null, audio: "audio/merchant/outro.mp3", dur: 14.5, accent: "#FF4A00" },
];

export const SHOPPER: Scene[] = [
  { id: "title", frame: null, caption: null, audio: "audio/shopper/title.mp3", dur: 13.0, accent: "#FF4A00" },
  { id: "home", frame: "frames/store_home.png", caption: "Start with your vehicle", audio: "audio/shopper/home.mp3", dur: 18.0, accent: "#FF4A00" },
  { id: "collection", frame: "frames/store_collection.png", caption: "Compatible parts only", audio: "audio/shopper/collection.mp3", dur: 16.5, accent: "#FF4A00" },
  { id: "pdp_exact", frame: "frames/pdp_exact.png", caption: "Guaranteed exact fit", audio: "audio/shopper/pdp_exact.mp3", dur: 17.0, accent: "#15804C" },
  { id: "pdp_nofit", frame: "frames/pdp_nofit.png", caption: "Incompatible, up front", audio: "audio/shopper/pdp_nofit.mp3", dur: 16.5, accent: "#C62828" },
  { id: "pdp_universal", frame: "frames/pdp_universal.png", caption: "Universal still works", audio: "audio/shopper/pdp_universal.mp3", dur: 15.5, accent: "#1565C0" },
  { id: "garage", frame: "frames/store_garage.png", caption: "A garage that remembers", audio: "audio/shopper/garage.mp3", dur: 15.5, accent: "#FF4A00" },
  { id: "support", frame: "frames/store_support.png", caption: "Confidence after checkout", audio: "audio/shopper/support.mp3", dur: 15.5, accent: "#FF4A00" },
  { id: "outro", frame: null, caption: null, audio: "audio/shopper/outro.mp3", dur: 14.0, accent: "#FF4A00" },
];
