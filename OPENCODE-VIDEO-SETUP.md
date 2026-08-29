# OpenCode Video Generation Setup for Vehicle Selector Pro

## 🎬 **OpenCode Video Generation Options**

Based on research, here are the main OpenCode video generation tools available:

### **Option 1: Brandly Plugin (Recommended)**
**GitHub:** https://github.com/Dream-Pixels-Forge/brandly-plugin

**Features:**
- AI video orchestrator for OpenCode
- Turns product ideas into marketing videos
- Multi-agent pipeline for professional results
- Tools for project management, editing, and export

**Key Tools:**
- `brandly_start` - Start new video project
- `brandly_run_project` - Run pipeline phases
- `brandly_export` - Export final video
- `brandly_render_video` - Render with Remotion
- `brandly_assemble` - Assemble clips with transitions

**Setup:**
```bash
# OpenCode auto-installs via bun install
# The brandly_* tools will be available automatically
```

### **Option 2: OpenCode Nanobanana**
**GitHub:** https://github.com/48Nauts-Operator/opencode-nanobanana

**Features:**
- FREE image generation with Nano Banana (Gemini 2.5 Flash)
- Video generation with Veo 3.1
- Storyboard video generation with transitions
- Image-to-video animation
- Character consistency across scenes

**Capabilities:**
- Parallel scene generation
- Professional transitions
- Native audio generation
- Background music support
- 720P/1080P output

### **Option 3: Spark Video (Cross-Platform)**
**GitHub:** https://github.com/JohnKeating1997/spark-video

**Features:**
- AI video production skill
- Premise → Screenplay → Storyboard → Render → Review → Final MP4
- Consistent characters, sets, props
- Works across Claude Code, Cursor, Qwen Code, Codex
- One-prompt installation

**Setup:**
```bash
# In any agent that supports skills:
git clone https://github.com/JohnKeating1997/spark-video.git \
  ~/.claude/skills/spark-video
# or ~/.cursor/skills/spark-video
# or ~/.qwen/skills/spark-video
```

### **Option 4: MuleRouter Wan 2.5 Spark**
**Website:** https://www.mulerouter.ai/models/wan2-5-i2v-spark

**Features:**
- Cost-effective image-to-video generation
- 720P/1080P support
- Auto-generated audio
- ~33% cost savings vs standard Wan 2.5

## 🎯 **Recommended Approach for Vehicle Selector Pro**

### **Phase 1: Setup OpenCode Video Generation**
1. Install **Brandly Plugin** (most comprehensive for product demos)
2. Install **Spark Video** as backup (cross-platform support)
3. Configure for web app demonstration

### **Phase 2: Create Demo Video**
1. Use `brandly_start` to initiate project
2. Provide Vehicle Selector Pro as product context
3. Let AI generate screen recording of Rails app
4. AI will add professional narration
5. Export final polished video

### **Phase 3: Integration with Existing Demo**
1. Combine with existing `demo/index.html` interface
2. Use AI to navigate the actual Rails app
3. Generate professional voiceover
4. Create marketing-quality video

## 📋 **Immediate Next Steps**

### **Manual Steps Required:**
1. **Close your IDE** (Windsurf/Cursor) to release Opencode and ZCODE folders
2. **Move `.env` contents to `secrets/.env`**
3. **Delete old `.env` file**

### **After Manual Steps, I Will:**
1. Remove Opencode and ZCODE folders
2. Set up OpenCode video generation plugins
3. Configure video generation for Vehicle Selector Pro
4. Verify no secrets in git tracking
5. Get your confirmation before GitHub push

## 🚀 **Video Generation Workflow**

### **Using Brandly Plugin:**
```bash
# Start new project
brandly_start "Vehicle Selector Pro Shopify App Demo"

# Run pipeline phases
brandly_run_project

# Approve and advance
brandly_approve

# Export final video
brandly_export
```

### **Using Spark Video:**
```bash
# In OpenCode/Cursor:
"Use spark-video to create a 3-minute demo video of Vehicle Selector Pro Rails app. Show admin dashboard, storefront vehicle selector, and fitment management."
```

## 💡 **Why This Approach is Better Than OBS**

**Advantages:**
- ✅ **Fully automated** - No manual recording
- ✅ **AI-powered narration** - Professional voiceover
- ✅ **Smart editing** - AI selects best segments
- ✅ **Professional transitions** - Automatic scene transitions
- ✅ **Character consistency** - If using animated characters
- ✅ **Cost-effective** - Many free tiers available
- ✅ **Reproducible** - Can regenerate as needed

**VS OBS:**
- ❌ Manual recording required
- ❌ Manual editing needed
- ❌ Professional voiceover requires separate recording
- ❌ Time-consuming process
- ❌ Less reproducible

## 🎯 **Final Deliverable**

The AI-generated video will show:
1. **Admin Dashboard** - Polaris-styled interface
2. **Storefront Selector** - Cascading YMM filters
3. **Fitment Management** - Product vehicle mapping
4. **Professional narration** - AI voiceover explaining features
5. **Marketing-quality editing** - Professional transitions and effects

---

**This approach leverages OpenCode's advanced AI video generation capabilities to create a professional demo video automatically, exactly as you requested.**