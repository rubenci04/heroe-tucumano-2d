const AudioSFX = {
    ctx: null,
    init() {
        if (!this.ctx) {
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            if (AudioContext) {
                this.ctx = new AudioContext();
            }
        }
        if (this.ctx && this.ctx.state === 'suspended') {
            this.ctx.resume();
        }
    },
    play(tipo) {
        if (!this.ctx) return;
        try {
            const now = this.ctx.currentTime;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.connect(gain);
            gain.connect(this.ctx.destination);

            if (tipo === 'salto') {
                osc.type = 'square';
                osc.frequency.setValueAtTime(160, now);
                osc.frequency.exponentialRampToValueAtTime(480, now + 0.12);
                gain.gain.setValueAtTime(0.12, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.12);
                osc.start(now);
                osc.stop(now + 0.12);
            } else if (tipo === 'disparo_naranja') {
                osc.type = 'triangle';
                osc.frequency.setValueAtTime(420, now);
                osc.frequency.exponentialRampToValueAtTime(140, now + 0.10);
                gain.gain.setValueAtTime(0.15, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.10);
                osc.start(now);
                osc.stop(now + 0.10);
            } else if (tipo === 'disparo_cascote') {
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(240, now);
                osc.frequency.exponentialRampToValueAtTime(70, now + 0.14);
                gain.gain.setValueAtTime(0.18, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.14);
                osc.start(now);
                osc.stop(now + 0.14);
            } else if (tipo === 'empanada') {
                osc.type = 'sine';
                osc.frequency.setValueAtTime(523.25, now);
                osc.frequency.setValueAtTime(659.25, now + 0.05);
                osc.frequency.setValueAtTime(783.99, now + 0.10);
                gain.gain.setValueAtTime(0.14, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.20);
                osc.start(now);
                osc.stop(now + 0.20);
            } else if (tipo === 'achilata') {
                osc.type = 'sine';
                osc.frequency.setValueAtTime(600, now);
                osc.frequency.exponentialRampToValueAtTime(950, now + 0.15);
                gain.gain.setValueAtTime(0.15, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.18);
                osc.start(now);
                osc.stop(now + 0.18);
            } else if (tipo === 'sanguche') {
                osc.type = 'square';
                osc.frequency.setValueAtTime(300, now);
                osc.frequency.setValueAtTime(420, now + 0.08);
                osc.frequency.setValueAtTime(560, now + 0.16);
                osc.frequency.setValueAtTime(800, now + 0.24);
                gain.gain.setValueAtTime(0.18, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.38);
                osc.start(now);
                osc.stop(now + 0.38);
            } else if (tipo === 'golpe') {
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(150, now);
                osc.frequency.exponentialRampToValueAtTime(40, now + 0.15);
                gain.gain.setValueAtTime(0.20, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.15);
                osc.start(now);
                osc.stop(now + 0.15);
            } else if (tipo === 'danio') {
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(200, now);
                osc.frequency.linearRampToValueAtTime(70, now + 0.22);
                gain.gain.setValueAtTime(0.22, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.22);
                osc.start(now);
                osc.stop(now + 0.22);
            } else if (tipo === 'victoria') {
                osc.type = 'triangle';
                [261.63, 329.63, 392.00, 523.25].forEach((freq, idx) => {
                    osc.frequency.setValueAtTime(freq, now + idx * 0.12);
                });
                gain.gain.setValueAtTime(0.20, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.55);
                osc.start(now);
                osc.stop(now + 0.55);
            } else if (tipo === 'cabezazo') {
                osc.type = 'square';
                osc.frequency.setValueAtTime(500, now);
                osc.frequency.exponentialRampToValueAtTime(90, now + 0.20);
                gain.gain.setValueAtTime(0.22, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.20);
                osc.start(now);
                osc.stop(now + 0.20);
            } else if (tipo === 'alerta') {
                osc.type = 'square';
                osc.frequency.setValueAtTime(700, now);
                osc.frequency.setValueAtTime(500, now + 0.10);
                osc.frequency.setValueAtTime(700, now + 0.20);
                gain.gain.setValueAtTime(0.12, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.32);
                osc.start(now);
                osc.stop(now + 0.32);
            }
        } catch (e) {
            // Audio no disponible
        }
    }
};

