/**
 * Vehicle Selector Pro - Storefront Client
 * Pure Vanilla JavaScript ES6+ Theme App Extension Controller
 */

(function() {
  'use strict';

  const STORAGE_KEY_ACTIVE = 'vsp_active_vehicle';
  const STORAGE_KEY_GARAGE = 'vsp_customer_garage';
  const PROXY_BASE_URL = '/apps/vehicle-selector';

  class VehicleSelectorClient {
    constructor() {
      this.cache = new Map();
      this.activeVehicle = this.loadActiveVehicle();
      this.garage = this.loadGarage();

      this.initWidgets();
      this.initPdpFitmentBadges();
      this.bindGlobalEvents();
    }

    // --- Storage & Garage Management ---

    loadActiveVehicle() {
      try {
        const item = localStorage.getItem(STORAGE_KEY_ACTIVE);
        return item ? JSON.parse(item) : null;
      } catch (e) {
        return null;
      }
    }

    saveActiveVehicle(vehicle) {
      this.activeVehicle = vehicle;
      try {
        if (vehicle) {
          localStorage.setItem(STORAGE_KEY_ACTIVE, JSON.stringify(vehicle));
          this.addToGarage(vehicle);
        } else {
          localStorage.removeItem(STORAGE_KEY_ACTIVE);
        }
      } catch (e) {
        console.warn('[VSP] LocalStorage write error', e);
      }

      // Dispatch Custom Event for theme/other apps
      window.dispatchEvent(new CustomEvent('vsp:vehicleChanged', { detail: { vehicle } }));
      this.updateAllPdpBadges();
      this.renderAllActiveVehicleBars();
    }

    loadGarage() {
      try {
        const list = localStorage.getItem(STORAGE_KEY_GARAGE);
        return list ? JSON.parse(list) : [];
      } catch (e) {
        return [];
      }
    }

    addToGarage(vehicle) {
      if (!vehicle) return;
      let list = this.loadGarage();
      // Remove duplicate if already present
      list = list.filter(v => !(v.year === vehicle.year && v.make.toLowerCase() === vehicle.make.toLowerCase() && v.model.toLowerCase() === vehicle.model.toLowerCase()));
      list.unshift(vehicle);
      if (list.length > 5) list = list.slice(0, 5); // max 5
      this.garage = list;
      try {
        localStorage.setItem(STORAGE_KEY_GARAGE, JSON.stringify(list));
      } catch (e) {}
    }

    removeFromGarage(index) {
      this.garage.splice(index, 1);
      try {
        localStorage.setItem(STORAGE_KEY_GARAGE, JSON.stringify(this.garage));
      } catch (e) {}
      this.renderGarageDropdowns();
    }

    // --- Network & Cache Layer ---

    async fetchApi(endpoint, params = {}) {
      // On a live storefront, Shopify's App Proxy injects the HMAC signature.
      // For the local storefront preview (served by the Rails app itself)
      // there is no proxy, so use the development-only verification bypass.
      const host = window.location.hostname;
      if (host === 'localhost' || host === '127.0.0.1') {
        params = Object.assign({ skip_proxy_verify: 'true' }, params);
      }
      const query = new URLSearchParams(params).toString();
      const url = `${PROXY_BASE_URL}/${endpoint}${query ? '?' + query : ''}`;

      if (this.cache.has(url)) {
        return this.cache.get(url);
      }

      try {
        const res = await fetch(url, {
          headers: { 'Accept': 'application/json' }
        });
        if (!res.ok) throw new Error(`HTTP error ${res.status}`);
        const data = await res.json();
        this.cache.set(url, data);
        return data;
      } catch (err) {
        console.error(`[VSP] Failed fetching ${endpoint}:`, err);
        return { success: false, error: err.message };
      }
    }

    // --- Filter Widget Initialization ---

    initWidgets() {
      const widgets = document.querySelectorAll('.vsp-widget-container');
      widgets.forEach(widget => this.setupWidget(widget));
    }

    async setupWidget(widget) {
      const yearSelect = widget.querySelector('.vsp-select-year');
      const makeSelect = widget.querySelector('.vsp-select-make');
      const modelSelect = widget.querySelector('.vsp-select-model');
      const trimSelect = widget.querySelector('.vsp-select-trim');
      const engineSelect = widget.querySelector('.vsp-select-engine');
      const searchBtn = widget.querySelector('.vsp-btn-search');
      const resetBtn = widget.querySelector('.vsp-btn-reset');
      const garageBtn = widget.querySelector('.vsp-garage-btn');
      const garageDropdown = widget.querySelector('.vsp-garage-dropdown');

      // Populate Years
      const yearsData = await this.fetchApi('years');
      if (yearsData.success && yearsData.years) {
        yearSelect.innerHTML = `<option value="">Select Year</option>` +
          yearsData.years.map(y => `<option value="${y}">${y}</option>`).join('');
      }

      // Year Change Listener
      yearSelect.addEventListener('change', async () => {
        const year = yearSelect.value;
        this.resetSelect(makeSelect, 'Select Make');
        this.resetSelect(modelSelect, 'Select Model');
        if (trimSelect) this.resetSelect(trimSelect, 'Select Trim');
        if (engineSelect) this.resetSelect(engineSelect, 'Select Engine');
        if (searchBtn) searchBtn.disabled = true;

        if (!year) return;

        makeSelect.disabled = true;
        const res = await this.fetchApi('makes', { year });
        makeSelect.disabled = false;

        if (res.success && res.makes) {
          makeSelect.innerHTML = `<option value="">Select Make</option>` +
            res.makes.map(m => `<option value="${m}">${m}</option>`).join('');
        }
      });

      // Make Change Listener
      makeSelect.addEventListener('change', async () => {
        const year = yearSelect.value;
        const make = makeSelect.value;
        this.resetSelect(modelSelect, 'Select Model');
        if (trimSelect) this.resetSelect(trimSelect, 'Select Trim');
        if (engineSelect) this.resetSelect(engineSelect, 'Select Engine');
        if (searchBtn) searchBtn.disabled = true;

        if (!year || !make) return;

        modelSelect.disabled = true;
        const res = await this.fetchApi('models', { year, make });
        modelSelect.disabled = false;

        if (res.success && res.models) {
          modelSelect.innerHTML = `<option value="">Select Model</option>` +
            res.models.map(m => `<option value="${m}">${m}</option>`).join('');
        }
      });

      // Model Change Listener
      modelSelect.addEventListener('change', async () => {
        const year = yearSelect.value;
        const make = makeSelect.value;
        const model = modelSelect.value;
        if (trimSelect) this.resetSelect(trimSelect, 'Select Trim');
        if (engineSelect) this.resetSelect(engineSelect, 'Select Engine');

        if (!year || !make || !model) {
          if (searchBtn) searchBtn.disabled = true;
          return;
        }

        if (searchBtn) searchBtn.disabled = false;

        if (trimSelect) {
          trimSelect.disabled = true;
          const res = await this.fetchApi('trims', { year, make, model });
          trimSelect.disabled = false;
          if (res.success && res.trims && res.trims.length > 0) {
            trimSelect.innerHTML = `<option value="">All Trims</option>` +
              res.trims.map(t => `<option value="${t}">${t}</option>`).join('');
          } else {
            trimSelect.innerHTML = `<option value="">Standard</option>`;
          }
        }
      });

      // Trim Change Listener
      if (trimSelect) {
        trimSelect.addEventListener('change', async () => {
          const year = yearSelect.value;
          const make = makeSelect.value;
          const model = modelSelect.value;
          const trim = trimSelect.value;

          if (engineSelect && year && make && model) {
            engineSelect.disabled = true;
            const res = await this.fetchApi('engines', { year, make, model, trim });
            engineSelect.disabled = false;
            if (res.success && res.engines && res.engines.length > 0) {
              engineSelect.innerHTML = `<option value="">All Engines</option>` +
                res.engines.map(e => `<option value="${e}">${e}</option>`).join('');
            } else {
              engineSelect.innerHTML = `<option value="">Standard Engine</option>`;
            }
          }
        });
      }

      // Search Button Click
      if (searchBtn) {
        searchBtn.addEventListener('click', () => {
          const selected = {
            year: yearSelect.value,
            make: makeSelect.value,
            model: modelSelect.value,
            trim: trimSelect ? trimSelect.value : '',
            engine: engineSelect ? engineSelect.value : '',
            display_name: [yearSelect.value, makeSelect.value, modelSelect.value, trimSelect?.value, engineSelect?.value].compactBlank().join(' ')
          };

          this.saveActiveVehicle(selected);

          // Redirect to collection or search page with filter
          const filterParam = widget.dataset.filterParam || 'filter.v.m.custom.vehicle_fitment';
          const collectionHandle = widget.dataset.collectionHandle || 'all';
          const token = `${selected.year}|${selected.make.toLowerCase()}|${selected.model.toLowerCase()}`;

          const targetUrl = `/collections/${collectionHandle}?${encodeURIComponent(filterParam)}=${encodeURIComponent(token)}`;
          window.location.href = targetUrl;
        });
      }

      // Reset Button Click
      if (resetBtn) {
        resetBtn.addEventListener('click', () => {
          this.saveActiveVehicle(null);
          this.resetSelect(yearSelect, 'Select Year');
          this.resetSelect(makeSelect, 'Select Make');
          this.resetSelect(modelSelect, 'Select Model');
          if (trimSelect) this.resetSelect(trimSelect, 'Select Trim');
          if (engineSelect) this.resetSelect(engineSelect, 'Select Engine');
          if (searchBtn) searchBtn.disabled = true;
          // Repopulate years
          this.setupWidget(widget);
        });
      }

      // Garage Toggle
      if (garageBtn && garageDropdown) {
        garageBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          garageDropdown.classList.toggle('vsp-show');
          this.renderGarageDropdowns();
        });
      }
    }

    resetSelect(selectElement, defaultText) {
      if (!selectElement) return;
      selectElement.innerHTML = `<option value="">${defaultText}</option>`;
      selectElement.value = '';
    }

    // --- Garage Dropdown Render ---

    renderGarageDropdowns() {
      const dropdowns = document.querySelectorAll('.vsp-garage-dropdown');
      dropdowns.forEach(dropdown => {
        if (!this.garage || this.garage.length === 0) {
          dropdown.innerHTML = `<div style="padding: 12px; text-align: center; color: #888; font-size: 13px;">Your Garage is empty.<br/>Select a vehicle above to save it.</div>`;
          return;
        }

        dropdown.innerHTML = `
          <div style="padding: 6px 12px; font-size: 11px; font-weight: 700; text-transform: uppercase; color: #666; border-bottom: 1px solid #eee;">Saved in Garage</div>
          ${this.garage.map((veh, idx) => `
            <div class="vsp-garage-item ${this.activeVehicle && this.activeVehicle.display_name === veh.display_name ? 'active' : ''}" data-index="${idx}">
              <div>
                <strong>${veh.year} ${veh.make} ${veh.model}</strong>
                ${veh.trim || veh.engine ? `<div style="font-size: 11px; color: #888;">${[veh.trim, veh.engine].compactBlank().join(' • ')}</div>` : ''}
              </div>
              <button class="vsp-garage-remove" data-remove-index="${idx}" style="background: none; border: none; color: #999; cursor: pointer; font-size: 16px;">×</button>
            </div>
          `).join('')}
        `;

        dropdown.querySelectorAll('.vsp-garage-item').forEach(item => {
          item.addEventListener('click', (e) => {
            if (e.target.classList.contains('vsp-garage-remove')) return;
            const index = parseInt(item.dataset.index);
            const veh = this.garage[index];
            if (veh) {
              this.saveActiveVehicle(veh);
              dropdown.classList.remove('vsp-show');
            }
          });
        });

        dropdown.querySelectorAll('.vsp-garage-remove').forEach(btn => {
          btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const index = parseInt(btn.dataset.removeIndex);
            this.removeFromGarage(index);
          });
        });
      });
    }

    renderAllActiveVehicleBars() {
      const bars = document.querySelectorAll('.vsp-active-vehicle-bar');
      bars.forEach(bar => {
        if (this.activeVehicle) {
          bar.style.display = 'flex';
          const nameSpan = bar.querySelector('.vsp-active-vehicle-name');
          if (nameSpan) nameSpan.textContent = this.activeVehicle.display_name;
        } else {
          bar.style.display = 'none';
        }
      });
    }

    // --- Product Detail Page (PDP) Fitment Badge ---

    initPdpFitmentBadges() {
      this.updateAllPdpBadges();
    }

    async updateAllPdpBadges() {
      const badges = document.querySelectorAll('.vsp-pdp-fitment-badge');
      if (badges.length === 0) return;

      for (const badge of badges) {
        const productId = badge.dataset.productId;
        if (!productId) continue;

        if (!this.activeVehicle) {
          badge.className = 'vsp-pdp-fitment-badge vsp-fit-unselected';
          badge.innerHTML = `
            <div class="vsp-badge-icon">🚗</div>
            <div class="vsp-badge-content">
              <div class="vsp-badge-title">Select Your Vehicle to Confirm Fitment</div>
              <div class="vsp-badge-description">Ensure this part matches your year, make, model, and trim before ordering.</div>
            </div>
          `;
          continue;
        }

        // Call fitment check endpoint
        const res = await this.fetchApi('check_fitment', {
          product_id: productId,
          year: this.activeVehicle.year,
          make: this.activeVehicle.make,
          model: this.activeVehicle.model,
          trim: this.activeVehicle.trim,
          engine: this.activeVehicle.engine
        });

        if (res.success && res.data) {
          const fit = res.data;
          if (fit.fitment_type === 'universal') {
            badge.className = 'vsp-pdp-fitment-badge vsp-fit-universal';
            badge.innerHTML = `
              <div class="vsp-badge-icon">🌐</div>
              <div class="vsp-badge-content">
                <div class="vsp-badge-title">Universal Fitment</div>
                <div class="vsp-badge-description">${fit.notes || 'This product is designed to fit all vehicle configurations.'}</div>
              </div>
            `;
          } else if (fit.fits) {
            badge.className = 'vsp-pdp-fitment-badge vsp-fit-exact';
            badge.innerHTML = `
              <div class="vsp-badge-icon">✔</div>
              <div class="vsp-badge-content">
                <div class="vsp-badge-title">Guaranteed Exact Fit for ${this.activeVehicle.display_name}</div>
                <div class="vsp-badge-description">${fit.notes || '100% Fitment Guarantee. Ready for installation.'}</div>
              </div>
            `;
          } else {
            badge.className = 'vsp-pdp-fitment-badge vsp-fit-none';
            badge.innerHTML = `
              <div class="vsp-badge-icon">✕</div>
              <div class="vsp-badge-content">
                <div class="vsp-badge-title">Does NOT Fit ${this.activeVehicle.display_name}</div>
                <div class="vsp-badge-description">${fit.notes || 'This product is not compatible with your active vehicle.'}</div>
              </div>
            `;
          }
        }
      }
    }

    bindGlobalEvents() {
      // Close dropdowns on outside click
      document.addEventListener('click', () => {
        document.querySelectorAll('.vsp-garage-dropdown').forEach(d => d.classList.remove('vsp-show'));
      });
    }
  }

  // Array helper
  Array.prototype.compactBlank = function() {
    return this.filter(item => item !== null && item !== undefined && item !== '');
  };

  // Auto-init on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => new VehicleSelectorClient());
  } else {
    new VehicleSelectorClient();
  }
})();
