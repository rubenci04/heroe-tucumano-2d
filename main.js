// =============================================================================
// HÉROE TUCUMANO 2D ARCADE - ARCHIVO PRINCIPAL: main.js
// VERSIÓN CORREGIDA Y ACTUALIZADA
// =============================================================================

const ANCHO_VISTA = 800;
const ALTO_VISTA = 450;
const ANCHO_MUNDO = 8000;

// Carriles 2.5D
const CARRIL_SUPERIOR_Y = 370;
const CARRIL_INFERIOR_Y = 415;
const Y_ESCENARIO = 345;

// =============================================================================
// SINTETIZADOR DE AUDIO RETRO (Web Audio API)
// =============================================================================
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

const config = {
    type: Phaser.AUTO,
    width: ANCHO_VISTA,
    height: ALTO_VISTA,
    parent: 'contenedor-juego',
    pixelArt: true,
    scale: {
        mode: Phaser.Scale.FIT,
        autoCenter: Phaser.Scale.CENTER_BOTH
    },
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 1300 },
            debug: false
        }
    },
    scene: {
        preload: preload,
        create: create,
        update: update
    }
};

const game = new Phaser.Game(config);

// =============================================================================
// GESTOR DE CONTROLES TÁCTILES Y ENTRADA VIRTUAL (Móviles / Touch)
// =============================================================================
const controlesTactiles = {
    left: false,
    right: false,
    up: false,
    down: false,
    salto: false,
    disparo: false,
    cabezazo: false,
    _justUp: false,
    _justDown: false,
    _justSalto: false,
    _justDisparo: false,
    _justCabezazo: false,

    setButton(name, isPressed) {
        if (isPressed) {
            AudioSFX.init();
            if (navigator.vibrate) {
                try { navigator.vibrate(12); } catch (e) {}
            }
            if (name === 'up' && !this.up) this._justUp = true;
            if (name === 'down' && !this.down) this._justDown = true;
            if (name === 'salto' && !this.salto) this._justSalto = true;
            if (name === 'disparo' && !this.disparo) this._justDisparo = true;
            if (name === 'cabezazo' && !this.cabezazo) this._justCabezazo = true;
        }
        this[name] = isPressed;

        if (isPressed) {
            if (enCinematica && game && game.scene && game.scene.scenes[0]) {
                avanzarCinematica(game.scene.scenes[0]);
            }
            window.dispatchEvent(new CustomEvent('arcade-button-pressed', { detail: { button: name } }));
        }
    },

    consumirJustUp() {
        const v = this._justUp;
        this._justUp = false;
        return v;
    },
    consumirJustDown() {
        const v = this._justDown;
        this._justDown = false;
        return v;
    },
    consumirJustSalto() {
        const v = this._justSalto;
        this._justSalto = false;
        return v;
    },
    consumirJustDisparo() {
        const v = this._justDisparo;
        this._justDisparo = false;
        return v;
    },
    consumirJustCabezazo() {
        const v = this._justCabezazo;
        this._justCabezazo = false;
        return v;
    },
    resetAll() {
        this.left = false;
        this.right = false;
        this.up = false;
        this.down = false;
        this.salto = false;
        this.disparo = false;
        this.cabezazo = false;
        this._justUp = false;
        this._justDown = false;
        this._justSalto = false;
        this._justDisparo = false;
        this._justCabezazo = false;
    }
};
window.ControlesTactiles = controlesTactiles;

// Variables de estado del jugador y del juego
let jugador, cursores, teclaZ, teclaX, teclaEnter, teclaC;
let fondoCerros, fondoUnificado, sueloRuta, sueloRuta2;
let proyectilesJugador, proyectilesEnemigos, hipsters, agentes, grandotes, colectivos, autosRuta, empanadas, potenciadores, achilatas, metaFinal;
let vidas = 3, salud = 3;
const MAX_SALUD = 3;
let puntos = 0, armaActual = 'NINGUNA', municion = 0, modoSanguchazo = false;
let textoVidas, barraVidaGrafico, textoPuntos, textoArma, textoEspecial, textoVidaJefe, bannerNotificacion;
let esInvulnerable = false, disparoPresionado = false, disparando = false, juegoTerminado = false;

// Variables de salto y control 2.5D
let estaSaltando = false;
let carrilActual = CARRIL_SUPERIOR_Y;
let tiempoInicioSalto = 0;
let vehiculoApoyado = null;
let cambiandoCarril = false;

// Nuevos estados para animaciones de recolección
let recolectando = false;
let cabezazoActivo = false;

// Variables del Jefe Final y Progresión
let jefe, jefeActivo = false, vidaJefe = 90, jefeInvulnerable = false, jefeAtacando = false;
let oleadasActivadas = [];
let arbolSaqueado = false;
let arbolNaranjasIntro;

// Variables de Cinemática, Diálogos e Insolación
let enCinematica = true;
let pasoCinematica = 0;
let textoNarradoGlobal, cajaTextoGlobal, actoresCinematica = {};
let solSprite, barraCalorGrafico, textoCalor, capaTinteCalor;
let nivelInsolacion = 0;
let insolacionActiva = false;
let tiempoUltimoDanioSol = 0;

function preload() {
    // Fondos
    this.load.image('fondo_cerros', 'assets/fondo_cerros.png');
    this.load.image('fusion_fondo', 'assets/fusion_fondos.png');
    this.load.image('suelo_ruta', 'assets/suelo_ruta.png');
    this.load.image('suelo_ruta2', 'assets/suelo_ruta2.png');

    // Props
    this.load.image('kiosco_coca', 'assets/kiosco_coca.png');
    this.load.image('parada_colectivo', 'assets/parada_colectivo.png');
    this.load.image('cartel_famailla', 'assets/cartel_famailla.png');
    this.load.image('palmera', 'assets/palmera.png');
    this.load.image('arbol_naranjas', 'assets/arbol_naranjas.png');
    this.load.image('gruta_virgen', 'assets/gruta_virgen.png');
    this.load.image('poste_luz', 'assets/poste_luz.png');
    this.load.image('montaña_cascote', 'assets/montaña_cascote.png');

    // Vehículos
    this.load.image('exprebus', 'assets/exprebus.png');
    this.load.image('tesa', 'assets/tesa.png');
    this.load.image('auto1', 'assets/auto1.png');
    this.load.image('auto2', 'assets/auto2.png');
    this.load.image('auto3', 'assets/auto3.png');
    this.load.image('camion_limones', 'assets/camion_limones.png');

    // Cinemática
    this.load.image('ciruja_comiendo', 'assets/ciruja comiendo.png');
    this.load.image('campeona_empanadas', 'assets/campeona empanadas.png');
    this.load.image('secuestro_campeona', 'assets/secuestro_campeona.png');

    // Sprites del Ciruja (básicos)
    this.load.image('ciruja_idle', 'assets/ciruja_idle.png');
    this.load.image('ciruja_run1', 'assets/ciruja_run1.png');
    this.load.image('ciruja_run2', 'assets/ciruja_run2.png');
    this.load.image('ciruja_run3', 'assets/ciruja_run3.png');
    this.load.image('ciruja_salto', 'assets/ciruja_salto.png');
    this.load.image('ciruja_disparo_naranja1', 'assets/ciruja_disparo_naranja1.png');
    this.load.image('ciruja_disparo_naranja2', 'assets/ciruja_disparo_naranja2.png');
    this.load.image('ciruja_disparo_cascote1', 'assets/ciruja_disparo_cascote1.png');
    this.load.image('ciruja_disparo_cascote2', 'assets/ciruja_disparo_cascote2.png');

    // [Nota para mí: Aquí agrego las nuevas secuencias de sprites que generé para recolectar y el cabezazo]
    for (let i = 1; i <= 5; i++) {
        this.load.image(`juntar_naranjas${i}`, `assets/juntar_naranjas${i}.png`);
        this.load.image(`juntar_cascote${i}`, `assets/juntar_cascote${i}.png`);
    }
    for (let i = 0; i <= 2; i++) {
        this.load.image(`ciruja_cabezazo${i}`, `assets/ciruja_cabezazo${i}.png`);
    }

    // Proyectiles e Ítems
    this.load.image('naranja', 'assets/naranja.png');
    this.load.image('cascote', 'assets/cascote.png');
    this.load.image('empanada', 'assets/empanada.png');
    this.load.image('sanguche', 'assets/sanguche.png');
    this.load.image('achilata', 'assets/achilata.png');
    this.load.image('sol', 'assets/sol.png');
    this.load.image('botella_agua', 'assets/botella_agua.png');
    this.load.image('bala', 'assets/bala.png');
    this.load.image('cofee', 'assets/cofee.png');

    // Enemigos y Palermitano
    this.load.image('hipster_agua1', 'assets/hipster_agua1.png');
    this.load.image('hipster_agua2', 'assets/hipster_agua2.png');
    this.load.image('hipster_run1', 'assets/hipster_run1.png');
    this.load.image('hipster_run2', 'assets/hipster_run2.png');
    this.load.image('hipster_run3', 'assets/hipster_run3.png');
    this.load.image('hipster_salto', 'assets/hipster_salto.png');

    this.load.image('agente_run1', 'assets/agente_run1.png');
    this.load.image('agente_run2', 'assets/agente_run2.png');
    this.load.image('agente_run3', 'assets/agente_run3.png');
    this.load.image('agente_salto', 'assets/agente_salto.png');
    this.load.image('agente_disparo_bala1', 'assets/agente_disparo_bala1.png');
    this.load.image('agente_disparo_bala2', 'assets/agente_disparo_bala2.png');

    this.load.image('grandote_run1', 'assets/grandote_run1.png');
    this.load.image('grandote_run2', 'assets/grandote_run2.png');
    this.load.image('grandote_salto', 'assets/grandote_salto.png');
    this.load.image('grandote_punch1', 'assets/grandote_punch1.png');
    this.load.image('grandote_punch2', 'assets/grandote_punch2.png');
    this.load.image('grandote_punch3', 'assets/grandote_punch3.png');

    this.load.image('final_boss_cofee1', 'assets/final_boss_cofee1.png');
    this.load.image('final_boss_cofee2', 'assets/final_boss_cofee2.png');
    this.load.image('final_boss_joke1', 'assets/final_boss_joke1.png');
    this.load.image('final_boss_joke2', 'assets/final_boss_joke2.png');
    this.load.image('final_boss_punch1', 'assets/final_boss_punch1.png');
    this.load.image('final_boss_punch2', 'assets/final_boss_punch2.png');
    this.load.image('final_boss_salto1', 'assets/final_boss_salto1.png');
    this.load.image('final_boss_salto2', 'assets/final_boss_salto2.png');
    this.load.image('final_boss_run1', 'assets/final_boss_run1.png');
    this.load.image('final_boss_run2', 'assets/final_boss_run2.png');
    this.load.image('final_boss_run3', 'assets/final_boss_run3.png');
}

function create() {
    juegoTerminado = false;
    enCinematica = true;
    pasoCinematica = 0;
    vidas = 3;
    salud = MAX_SALUD;
    puntos = 0;
    armaActual = 'NINGUNA';
    municion = 0;
    modoSanguchazo = false;
    disparando = false;
    esInvulnerable = false;
    estaSaltando = false;
    vehiculoApoyado = null;
    carrilActual = CARRIL_SUPERIOR_Y;
    cambiandoCarril = false;
    recolectando = false;
    cabezazoActivo = false;

    jefeActivo = false;
    vidaJefe = 90;
    jefeInvulnerable = false;
    jefeAtacando = false;
    oleadasActivadas = [];
    arbolSaqueado = false;
    nivelInsolacion = 0;
    insolacionActiva = false;

    this.physics.world.setBounds(0, 0, ANCHO_MUNDO + 400, ALTO_VISTA);

    // [Nota para mí: Aquí ajusto el fondo para que abarque más, lo levanto en el eje Y y aumento el DisplaySize para que no queden huecos]
    fondoCerros = this.add.tileSprite(0, 0, ANCHO_VISTA, ALTO_VISTA, 'fondo_cerros')
        .setOrigin(0, 0).setScrollFactor(0).setDepth(0);

    fondoUnificado = this.add.image(0, -120, 'fusion_fondo')
        .setOrigin(0, 0)
        .setDisplaySize(ANCHO_MUNDO, ALTO_VISTA + 150)
        .setDepth(1.2);

    sueloRuta = this.add.tileSprite(0, Y_ESCENARIO - 20, ANCHO_VISTA, 160, 'suelo_ruta').setOrigin(0, 0).setScrollFactor(0).setDepth(1.5);
    sueloRuta2 = this.add.tileSprite(0, Y_ESCENARIO + 85, ANCHO_VISTA, 160, 'suelo_ruta2').setOrigin(0, 0).setScrollFactor(0).setDepth(1.6);

    // Escenografía Famaillá
    this.add.image(130, Y_ESCENARIO, 'cartel_famailla').setOrigin(0.5, 1).setScale(1.10).setDepth(2);
    this.add.image(350, Y_ESCENARIO, 'gruta_virgen').setOrigin(0.5, 1).setScale(0.72).setDepth(2);

    // [Nota para mí: El naranjo inicial ahora es estático, le quité el tween de latido para que el jugador interactúe una sola vez de forma visual]
    arbolNaranjasIntro = this.add.image(520, Y_ESCENARIO, 'arbol_naranjas').setOrigin(0.5, 1).setScale(0.85).setDepth(2);

    // Palmeras en Famaillá
    this.add.image(680, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);
    this.add.image(880, Y_ESCENARIO, 'kiosco_coca').setOrigin(0.5, 1).setScale(1.05).setDepth(2);
    this.add.image(1150, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);

    // Paradas de colectivos y naranjos distribuidos
    [2100, 3600, 4800, 6100, 7100].forEach(px => {
        this.add.image(px, Y_ESCENARIO, 'parada_colectivo').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
        this.add.image(px + 320, Y_ESCENARIO, 'arbol_naranjas').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    });

    const posicionesPostes = [1000, 1350, 1850, 2500, 3200, 3950, 4500, 5200, 5800, 6450, 7400];
    posicionesPostes.forEach(px => {
        this.add.image(px, Y_ESCENARIO, 'poste_luz').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    });

    // =========================================================================
    // CREACIÓN DE NUEVAS ANIMACIONES
    // =========================================================================
    if (!this.anims.exists('correr')) {
        this.anims.create({ key: 'correr', frames: [{ key: 'ciruja_run1' }, { key: 'ciruja_run2' }, { key: 'ciruja_run3' }], frameRate: 12, repeat: -1 });
        this.anims.create({ key: 'idle', frames: [{ key: 'ciruja_idle' }], frameRate: 1 });
        this.anims.create({ key: 'salto', frames: [{ key: 'ciruja_salto' }], frameRate: 1 });
        this.anims.create({ key: 'disparar_naranja', frames: [{ key: 'ciruja_disparo_naranja1' }, { key: 'ciruja_disparo_naranja2' }], frameRate: 14, repeat: 0 });
        this.anims.create({ key: 'disparar_cascote', frames: [{ key: 'ciruja_disparo_cascote1' }, { key: 'ciruja_disparo_cascote2' }], frameRate: 14, repeat: 0 });

        // Animaciones de recolección
        this.anims.create({
            key: 'juntar_naranjas',
            frames: [{ key: 'juntar_naranjas1' }, { key: 'juntar_naranjas2' }, { key: 'juntar_naranjas3' }, { key: 'juntar_naranjas4' }, { key: 'juntar_naranjas5' }],
            frameRate: 10, repeat: 0
        });
        this.anims.create({
            key: 'juntar_cascotes',
            frames: [{ key: 'juntar_cascote1' }, { key: 'juntar_cascote2' }, { key: 'juntar_cascote3' }, { key: 'juntar_cascote4' }, { key: 'juntar_cascote5' }],
            frameRate: 10, repeat: 0
        });

        // Animación Cabezazo
        this.anims.create({
            key: 'cabezazo_anim',
            frames: [{ key: 'ciruja_cabezazo0' }, { key: 'ciruja_cabezazo1' }, { key: 'ciruja_cabezazo2' }],
            frameRate: 12, repeat: 0
        });

        this.anims.create({ key: 'hipster_run', frames: [{ key: 'hipster_run1' }, { key: 'hipster_run2' }, { key: 'hipster_run3' }], frameRate: 8, repeat: -1 });
        this.anims.create({ key: 'hipster_salto', frames: [{ key: 'hipster_salto' }], frameRate: 1 });
        this.anims.create({ key: 'hipster_lanzar', frames: [{ key: 'hipster_agua1' }, { key: 'hipster_agua2' }], frameRate: 6, repeat: 0 });

        this.anims.create({ key: 'agente_run', frames: [{ key: 'agente_run1' }, { key: 'agente_run2' }, { key: 'agente_run3' }], frameRate: 7, repeat: -1 });
        this.anims.create({ key: 'agente_salto', frames: [{ key: 'agente_salto' }], frameRate: 1 });
        this.anims.create({ key: 'agente_disparar', frames: [{ key: 'agente_disparo_bala1' }, { key: 'agente_disparo_bala2' }], frameRate: 7, repeat: 0 });

        this.anims.create({ key: 'grandote_run', frames: [{ key: 'grandote_run1' }, { key: 'grandote_run2' }], frameRate: 6, repeat: -1 });
        this.anims.create({ key: 'grandote_salto', frames: [{ key: 'grandote_salto' }], frameRate: 1 });
        this.anims.create({ key: 'grandote_punch', frames: [{ key: 'grandote_punch1' }, { key: 'grandote_punch2' }, { key: 'grandote_punch3' }], frameRate: 9, repeat: 0 });

        this.anims.create({ key: 'boss_run', frames: [{ key: 'final_boss_run1' }, { key: 'final_boss_run2' }, { key: 'final_boss_run3' }], frameRate: 10, repeat: -1 });
        this.anims.create({ key: 'boss_salto', frames: [{ key: 'final_boss_salto1' }, { key: 'final_boss_salto2' }], frameRate: 6, repeat: 0 });
        this.anims.create({ key: 'boss_punch', frames: [{ key: 'final_boss_punch1' }, { key: 'final_boss_punch2' }], frameRate: 8, repeat: 0 });
        this.anims.create({ key: 'boss_joke', frames: [{ key: 'final_boss_joke1' }, { key: 'final_boss_joke2' }], frameRate: 4, repeat: -1 });
        this.anims.create({ key: 'boss_cofee', frames: [{ key: 'final_boss_cofee1' }, { key: 'final_boss_cofee2' }], frameRate: 9, repeat: 0 });
    }

    // =========================================================================
    // JUGADOR Y GRUPOS FÍSICOS
    // =========================================================================
    jugador = this.physics.add.sprite(70, carrilActual, 'ciruja_idle');
    jugador.setScale(0.42);
    jugador.setCollideWorldBounds(true);
    jugador.setBounce(0);
    jugador.setDragX(1800);
    jugador.body.allowGravity = false;

    this.cameras.main.setBounds(0, 0, ANCHO_MUNDO, ALTO_VISTA);

    proyectilesJugador = this.physics.add.group({ allowGravity: false });
    proyectilesEnemigos = this.physics.add.group({ allowGravity: false });
    colectivos = this.physics.add.group();
    autosRuta = this.physics.add.group();
    hipsters = this.physics.add.group();
    agentes = this.physics.add.group();
    grandotes = this.physics.add.group();
    achilatas = this.physics.add.group();

    // Colisiones con vehículos: ahora actúan como plataformas (one-way) desde arriba
    this.physics.add.collider(jugador, autosRuta, pararseSobreVehiculo, null, this);
    this.physics.add.collider(jugador, colectivos, pararseSobreVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, colectivos, impactarVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, autosRuta, impactarVehiculo, null, this);

    // Verificación de daño al tocar el frente de un vehículo (ya que la colisión real ahora solo bloquea desde arriba)
    this.physics.add.overlap(jugador, colectivos, choqueVehiculoFrontal, null, this);

    // [Nota para mí: Autos estáticos reubicados bien arriba en el carril superior, solo como decoración/plataforma, sin hacer daño]
    crearAutoEstadico(this, 1900, CARRIL_SUPERIOR_Y - 15, 'auto1', 0.95);
    crearAutoEstadico(this, 3100, CARRIL_SUPERIOR_Y - 15, 'camion_limones', 2.35);
    crearAutoEstadico(this, 5000, CARRIL_SUPERIOR_Y - 15, 'auto2', 0.95);
    crearAutoEstadico(this, 6700, CARRIL_SUPERIOR_Y - 15, 'auto3', 0.95);

    // Jefe Palermitano
    jefe = this.physics.add.sprite(7650, CARRIL_INFERIOR_Y, 'final_boss_joke1');
    jefe.setScale(0.78);
    jefe.setCollideWorldBounds(true);
    jefe.body.allowGravity = false;
    jefe.anims.play('boss_joke', true);

    empanadas = this.physics.add.group();
    [240, 750, 1350, 2000, 2700, 3400, 4100, 4900, 5600, 6300, 7000, 7500].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let emp = empanadas.create(posX, carril, 'empanada');
        emp.setScale(0.14);
        emp.body.allowGravity = false;
    });

    achilatas = this.physics.add.group();
    [3200, 3600, 4300, 5400, 6500, 7200].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let ach = achilatas.create(posX, carril, 'achilata');
        ach.setScale(0.24);
        ach.body.allowGravity = false;
    });

    potenciadores = this.physics.add.group();
    let montaña1 = potenciadores.create(1450, CARRIL_SUPERIOR_Y, 'montaña_cascote');
    montaña1.setScale(0.65);
    montaña1.body.allowGravity = false;
    montaña1.tipo = 'CASCOTES';

    let montaña2 = potenciadores.create(4400, CARRIL_SUPERIOR_Y, 'montaña_cascote');
    montaña2.setScale(0.65);
    montaña2.body.allowGravity = false;
    montaña2.tipo = 'CASCOTES';

    // Dos Sánguches de Milanesa
    crearSangucheMilanesa(this, 2800, CARRIL_INFERIOR_Y);
    crearSangucheMilanesa(this, 6200, CARRIL_INFERIOR_Y);

    metaFinal = this.add.rectangle(7900, 400, 80, 160, 0x00ff00, 0);
    this.physics.add.existing(metaFinal, true);

    // Overlaps
    this.physics.add.overlap(proyectilesJugador, hipsters, impactarEnemigo, null, this);
    this.physics.add.overlap(proyectilesJugador, agentes, impactarEnemigo, null, this);
    this.physics.add.overlap(proyectilesJugador, grandotes, impactarEnemigo, null, this);
    this.physics.add.overlap(proyectilesJugador, jefe, impactarJefe, null, this);

    this.physics.add.overlap(jugador, hipsters, interaccionJugadorEnemigo, null, this);
    this.physics.add.overlap(jugador, agentes, interaccionJugadorEnemigo, null, this);
    this.physics.add.overlap(jugador, grandotes, interaccionJugadorEnemigo, null, this);
    this.physics.add.overlap(jugador, jefe, interaccionJugadorJefe, null, this);

    this.physics.add.overlap(jugador, proyectilesEnemigos, impactarJugadorConProyectilEnemigo, null, this);
    this.physics.add.overlap(jugador, empanadas, recolectarEmpanada, null, this);
    this.physics.add.overlap(jugador, achilatas, recolectarAchilata, null, this);
    this.physics.add.overlap(jugador, potenciadores, recolectarPotenciador, null, this);
    this.physics.add.overlap(jugador, metaFinal, llegarALaMeta, null, this);

    // HUD
    textoVidas = this.add.text(20, 15, 'VIDAS: ' + vidas, { fontSize: '18px', fontFamily: 'Arial Black', fill: '#ffffff', stroke: '#000000', strokeThickness: 4 }).setScrollFactor(0).setDepth(100);
    barraVidaGrafico = this.add.graphics().setScrollFactor(0).setDepth(100);
    dibujarBarraSalud();

    textoPuntos = this.add.text(20, 62, 'PUNTOS: ' + puntos, { fontSize: '18px', fontFamily: 'Arial Black', fill: '#ffd700', stroke: '#000000', strokeThickness: 4 }).setScrollFactor(0).setDepth(100);
    textoArma = this.add.text(20, 88, 'ARMA: DESARMADO', { fontSize: '16px', fontFamily: 'Arial Black', fill: '#ff8800', stroke: '#000000', strokeThickness: 4 }).setScrollFactor(0).setDepth(100);
    textoEspecial = this.add.text(ANCHO_VISTA / 2, 28, '', { fontSize: '18px', fontFamily: 'Arial Black', fill: '#00ffcc', stroke: '#000000', strokeThickness: 5 }).setOrigin(0.5).setScrollFactor(0).setDepth(100);
    textoVidaJefe = this.add.text(ANCHO_VISTA - 340, 20, '', { fontSize: '16px', fontFamily: 'Arial Black', fill: '#ff3333', stroke: '#000000', strokeThickness: 4 }).setScrollFactor(0).setDepth(100);

    bannerNotificacion = this.add.text(ANCHO_VISTA / 2, 110, '', {
        fontSize: '18px', fontFamily: 'Arial Black', fill: '#ffff00', stroke: '#000000', strokeThickness: 5, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setAlpha(0).setDepth(100);

    capaTinteCalor = this.add.rectangle(ANCHO_VISTA / 2, ALTO_VISTA / 2, ANCHO_VISTA, ALTO_VISTA, 0xff5500, 0)
        .setScrollFactor(0).setDepth(90);

    solSprite = this.add.image(ANCHO_VISTA - 70, 70, 'sol')
        .setScrollFactor(0).setScale(0.40).setAlpha(0).setDepth(110);

    barraCalorGrafico = this.add.graphics().setScrollFactor(0).setDepth(110);
    textoCalor = this.add.text(ANCHO_VISTA - 160, 115, '', { fontSize: '13px', fontFamily: 'Arial Black', fill: '#ffaa00', stroke: '#000000', strokeThickness: 3 }).setScrollFactor(0).setDepth(110);

    cursores = this.input.keyboard.createCursorKeys();
    teclaZ = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.Z);
    teclaX = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.X);
    teclaEnter = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    teclaC = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.C);

    this.time.addEvent({ delay: 2200, callback: ejecutarRutinaJefe, callbackScope: this, loop: true });

    this.input.on('pointerdown', () => AudioSFX.init());
    this.input.keyboard.on('keydown', () => AudioSFX.init());
    window.addEventListener('touchstart', () => AudioSFX.init(), { passive: true });

    iniciarCinematicaInteractiva(this);
}

function update(time, delta) {
    if (!jugador.active || juegoTerminado) return;

    fondoCerros.tilePositionX = this.cameras.main.scrollX * 0.05;
    sueloRuta.tilePositionX = this.cameras.main.scrollX * 1.0;
    sueloRuta2.tilePositionX = this.cameras.main.scrollX * 1.0;

    if (enCinematica) {
        if (Phaser.Input.Keyboard.JustDown(teclaZ) ||
            Phaser.Input.Keyboard.JustDown(teclaX) ||
            Phaser.Input.Keyboard.JustDown(cursores.space) ||
            Phaser.Input.Keyboard.JustDown(teclaEnter) ||
            controlesTactiles.consumirJustDisparo() ||
            controlesTactiles.consumirJustSalto()) {
            avanzarCinematica(this);
        }
        return;
    }

    // [Nota para mí: Bloqueo de controles si el jugador está reproduciendo una animación de recolección o cabezazo]
    if (recolectando || cabezazoActivo) return;

    verificarProgresionOleadas(this);
    verificarRecoleccionArbol(this);
    actualizarSistemaInsolacion(this, time);

    const velocidadBase = modoSanguchazo ? 330 : 230;

    if (cursores.left.isDown || controlesTactiles.left) {
        jugador.setVelocityX(-velocidadBase);
        jugador.setFlipX(true);
        if (!estaSaltando && !disparando && !cambiandoCarril) jugador.anims.play('correr', true);
    } else if (cursores.right.isDown || controlesTactiles.right) {
        jugador.setVelocityX(velocidadBase);
        jugador.setFlipX(false);
        if (!estaSaltando && !disparando && !cambiandoCarril) jugador.anims.play('correr', true);
    } else {
        jugador.setVelocityX(0);
        if (!estaSaltando && !disparando && !cambiandoCarril) jugador.anims.play('idle', true);
    }

    if (!estaSaltando) {
        if (vehiculoApoyado) {
            let medioAncho = (vehiculoApoyado.displayWidth * 0.5) + 10;
            let fueraDelVehiculo = !vehiculoApoyado.active || Math.abs(jugador.x - vehiculoApoyado.x) > medioAncho;

            if (fueraDelVehiculo) {
                // [Nota para mí: Cuando el jugador camina hasta pasar el vehículo y cae, el vehículo reanuda su marcha velozmente y sale de la pantalla]
                if (vehiculoApoyado.dinamico && vehiculoApoyado.averiado) {
                    vehiculoApoyado.velocidadX = 650; // Se va rapidísimo hacia la derecha
                    vehiculoApoyado.clearTint();
                }
                vehiculoApoyado = null;
                if (jugador.y < carrilActual) {
                    estaSaltando = true;
                    jugador.body.allowGravity = true;
                }
            }
        } else if (!cambiandoCarril) {
            jugador.body.allowGravity = false;
            jugador.setVelocityY(0);

            if ((Phaser.Input.Keyboard.JustDown(cursores.up) || controlesTactiles.consumirJustUp()) && carrilActual === CARRIL_INFERIOR_Y) {
                cambiarDeCarril(this, CARRIL_SUPERIOR_Y);
            } else if ((Phaser.Input.Keyboard.JustDown(cursores.down) || controlesTactiles.consumirJustDown()) && carrilActual === CARRIL_SUPERIOR_Y) {
                cambiarDeCarril(this, CARRIL_INFERIOR_Y);
            }
        }

        if ((Phaser.Input.Keyboard.JustDown(cursores.space) || controlesTactiles.consumirJustSalto()) && !cambiandoCarril) {
            estaSaltando = true;
            vehiculoApoyado = null;
            tiempoInicioSalto = time;
            jugador.body.allowGravity = true;
            jugador.setVelocityY(-580);
            AudioSFX.play('salto');
            if (!disparando) jugador.anims.play('salto', true);
        }
    } else {
        const superoUmbralAterrizaje = (jugador.y >= carrilActual - 4 && jugador.body.velocity.y >= 0);
        const excedioTiempoVuelo = (time - tiempoInicioSalto > 950);

        if (superoUmbralAterrizaje || excedioTiempoVuelo) {
            jugador.y = carrilActual;
            jugador.body.allowGravity = false;
            jugador.setVelocityY(0);
            estaSaltando = false;
            vehiculoApoyado = null;
            if (!disparando) jugador.anims.play('idle', true);
        }

        if (cursores.space.isUp && !controlesTactiles.salto && jugador.body.velocity.y < -120) {
            jugador.setVelocityY(jugador.body.velocity.y * 0.50);
        }
    }

    if (teclaZ.isDown || teclaX.isDown || controlesTactiles.disparo) {
        if (!disparoPresionado) {
            intentarDisparo(this);
            disparoPresionado = true;
        }
    } else {
        disparoPresionado = false;
    }

    // Cabezazo activable solo bajo los efectos de la milanesa (modoSanguchazo)
    if (modoSanguchazo && !cabezazoActivo && (Phaser.Input.Keyboard.JustDown(teclaC) || controlesTactiles.consumirJustCabezazo()) && !estaSaltando && !cambiandoCarril) {
        ejecutarCabezazo(this);
    }

    actualizarColectivos(this);
    actualizarIAHipsters(this);
    actualizarIAAgentes(this);
    actualizarIAGrandotes(this);

    if (vehiculoApoyado && vehiculoApoyado.active) {
        jugador.setDepth(vehiculoApoyado.depth + 1);
    } else {
        jugador.setDepth(jugador.y + (jugador.displayHeight * 0.5));
    }

    hipsters.children.iterate(e => { if (e && e.active) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    agentes.children.iterate(e => { if (e && e.active) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    grandotes.children.iterate(e => { if (e && e.active) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    autosRuta.children.iterate(a => { if (a && a.active) a.setDepth(a.y); });
    colectivos.children.iterate(b => { if (b && b.active) b.setDepth(b.y); });
    empanadas.children.iterate(e => { if (e && e.active) e.setDepth(e.y); });
    achilatas.children.iterate(e => { if (e && e.active) e.setDepth(e.y); });
    potenciadores.children.iterate(e => { if (e && e.active) e.setDepth(e.y); });
    if (jefe && jefe.active) jefe.setDepth(jefe.y + (jefe.displayHeight * 0.5));

    const margen = 120;
    const scrollX = this.cameras.main.scrollX;

    proyectilesJugador.children.iterate((p) => {
        if (p && p.active) {
            p.angle += (p.velocidadGiro || 0);
            if (p.x < scrollX - margen || p.x > scrollX + ANCHO_VISTA + margen) {
                p.destroy();
            }
        }
    });

    proyectilesEnemigos.children.iterate((p) => {
        if (p && p.active) {
            p.angle += (p.velocidadGiro || 0);
            if (p.x < scrollX - margen || p.x > scrollX + ANCHO_VISTA + margen) {
                p.destroy();
            }
        }
    });

    if (jefe && jefe.active && !jefeActivo && jugador.x > 7300) {
        jefeActivo = true;
        actualizarBarraJefe();
        mostrarMensaje(this, '¡EL PALERMITANO MALVADO ESTÁ EN EL INGENIO!\n¡Derrótalo para salvar las empanadas!');
    }
}

// =============================================================================
// RECOLECCIÓN EN EL ÁRBOL DE NARANJAS
// =============================================================================
function verificarRecoleccionArbol(escena) {
    // [Nota para mí: Si pasa por el primer naranjo y aún no ha saqueado, fuerzo la animación y luego le doy el poder]
    if (!arbolSaqueado && jugador.x >= 490 && jugador.x <= 540 && carrilActual === CARRIL_SUPERIOR_Y) {
        arbolSaqueado = true;
        recolectando = true;
        jugador.setVelocityX(0);
        jugador.anims.play('juntar_naranjas', true);

        escena.time.delayedCall(500, () => {
            armaActual = 'NARANJA';
            municion = 999;
            AudioSFX.play('empanada');
            actualizarHUD();
            mostrarMensaje(escena, '¡HAS RECOLECTADO NARANJAS INFINITAS!\nPresiona Z o X para disparar');
            recolectando = false;
        });
    }
}

// =============================================================================
// CAMBIO DE CARRIL FLUIDO
// =============================================================================
function cambiarDeCarril(escena, nuevoCarril) {
    cambiandoCarril = true;
    let carrilOrigen = carrilActual;
    carrilActual = nuevoCarril;

    if (!disparando) jugador.anims.play('salto', true);
    AudioSFX.play('salto');

    // [Nota para mí: Interpolación mejorada para que el salto de carril sea más natural, con un Quad.easeInOut queda joya]
    escena.tweens.add({
        targets: jugador,
        y: carrilOrigen - 20,
        duration: 80,
        ease: 'Quad.easeOut',
        onComplete: () => {
            if (!jugador || !jugador.active) return;
            escena.tweens.add({
                targets: jugador,
                y: nuevoCarril,
                duration: 120,
                ease: 'Quad.easeIn',
                onComplete: () => {
                    cambiandoCarril = false;
                    if (jugador && jugador.active && !disparando && !estaSaltando) {
                        jugador.anims.play('idle', true);
                    }
                }
            });
        }
    });
}

// =============================================================================
// CINEMÁTICA INTERACTIVA
// =============================================================================
function iniciarCinematicaInteractiva(escena) {
    jugador.setVisible(false);
    escena.cameras.main.stopFollow();

    actoresCinematica.mesa = escena.add.image(190, CARRIL_SUPERIOR_Y, 'ciruja_comiendo').setScale(0.85).setDepth(50);
    actoresCinematica.campeona = escena.add.image(290, CARRIL_SUPERIOR_Y - 5, 'campeona_empanadas').setScale(0.80).setDepth(50);

    cajaTextoGlobal = escena.add.rectangle(ANCHO_VISTA / 2, ALTO_VISTA - 60, ANCHO_VISTA - 60, 75, 0x000000, 0.90)
        .setScrollFactor(0).setDepth(200);

    textoNarradoGlobal = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA - 60, 'FAMAILLÁ, CAPITAL DE LA EMPANADA.\nEL CIRUJA DISFRUTA DE UN MEDIODÍA DE PAZ...\n(Toca la pantalla o presiona Z para continuar)', {
        fontSize: '14px', fontFamily: 'Arial Black', fill: '#00ffcc', align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(201);

    escena.cameras.main.pan(400, ALTO_VISTA / 2, 1800, 'Sine.easeInOut');

    escena.input.on('pointerdown', () => {
        if (enCinematica) avanzarCinematica(escena);
    });
}

function avanzarCinematica(escena) {
    pasoCinematica++;

    if (pasoCinematica === 1) {
        escena.cameras.main.pan(300, ALTO_VISTA / 2, 800, 'Sine.easeInOut');
        textoNarradoGlobal.setText('¡ATAQUE SORPRESA!\nLOS AGENTES ATRAPAN A LA CAMPEONA DE LA EMPANADA...\n(Toca la pantalla o presiona Z para continuar)');
        textoNarradoGlobal.setFill('#ff3333');

        if (actoresCinematica.campeona) actoresCinematica.campeona.destroy();
        actoresCinematica.raptores = escena.add.image(290, CARRIL_SUPERIOR_Y - 5, 'secuestro_campeona').setScale(0.85).setDepth(55);
        actoresCinematica.jefeIntro = escena.add.sprite(200, CARRIL_SUPERIOR_Y - 10, 'final_boss_joke1').setScale(0.75).setDepth(56);
        actoresCinematica.jefeIntro.anims.play('boss_joke', true);

        AudioSFX.play('danio');
    } else if (pasoCinematica === 2) {
        textoNarradoGlobal.setText('PALERMITANO MALVADO: "¡LLEVENLA AL INGENIO!\n¡VAMOS A SERVIR LA EMPANADA DECONSTRUIDA EN FRASCO!"\n(Toca la pantalla o presiona Z para perseguirlos)');
        textoNarradoGlobal.setFill('#ffff00');

        escena.tweens.add({
            targets: actoresCinematica.raptores,
            x: 1100,
            duration: 2200,
            ease: 'Linear'
        });

        actoresCinematica.jefeIntro.anims.play('boss_run', true);
        escena.tweens.add({
            targets: actoresCinematica.jefeIntro,
            x: 1150,
            duration: 2000,
            ease: 'Linear',
            onComplete: () => {
                if (actoresCinematica.raptores) actoresCinematica.raptores.destroy();
                if (actoresCinematica.jefeIntro) actoresCinematica.jefeIntro.destroy();
            }
        });
    } else if (pasoCinematica === 3) {
        if (cajaTextoGlobal) cajaTextoGlobal.destroy();
        if (textoNarradoGlobal) textoNarradoGlobal.destroy();
        if (actoresCinematica.mesa) actoresCinematica.mesa.destroy();

        jugador.setPosition(80, CARRIL_SUPERIOR_Y);
        carrilActual = CARRIL_SUPERIOR_Y;
        estaSaltando = false;
        vehiculoApoyado = null;
        jugador.setVisible(true);
        enCinematica = false;

        escena.cameras.main.startFollow(jugador, true, 0.08, 0.08);
        mostrarMensaje(escena, '¡SALVA LA RECETA TRADICIONAL!\nAVANZA POR LA RUTA 38');
    }
}

// =============================================================================
// PLATAFORMAS Y VEHÍCULOS DINÁMICOS
// =============================================================================
function crearAutoEstadico(escena, x, carrilY, spriteKey, escala) {
    let auto = autosRuta.create(x, carrilY + 4, spriteKey);
    auto.setOrigin(0.5, 1);
    auto.setScale(escala);
    auto.setDepth(carrilY);
    auto.dinamico = false;
    auto.averiado = false;
    auto.setImmovable(true);
    auto.body.allowGravity = false;
    // [Nota para mí: checkCollision.up = true crea el efecto de "plataforma" o techo, para no cruzarlo por la mitad]
    auto.body.checkCollision.up = true;
    auto.body.checkCollision.down = false;
    auto.body.checkCollision.left = false;
    auto.body.checkCollision.right = false;

    let ancho = auto.width * 0.85;
    let alto = auto.height * 0.75;
    auto.body.setSize(ancho, alto);
    auto.body.setOffset((auto.width - ancho) / 2, auto.height - alto);
}

function lanzarColectivoDinámico(escena, x, spriteKey) {
    let carrilY = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y + 15 : CARRIL_INFERIOR_Y + 10;
    let bus = colectivos.create(x, carrilY, spriteKey);
    bus.setOrigin(0.5, 1);
    bus.setScale(2.35);
    bus.setDepth(carrilY);
    bus.vida = 5;
    bus.velocidadX = -450; // Vienen rápido en contra
    bus.dinamico = true;
    bus.averiado = false;
    bus.setImmovable(true);
    bus.body.allowGravity = false;

    bus.body.checkCollision.up = true;
    bus.body.checkCollision.down = false;
    bus.body.checkCollision.left = false;
    bus.body.checkCollision.right = false;

    let anchoReal = bus.width * 0.88;
    let altoReal = bus.height * 0.88;
    bus.body.setSize(anchoReal, altoReal);
    bus.body.setOffset((bus.width - anchoReal) / 2, bus.height - altoReal);

    escena.tweens.add({
        targets: bus, y: carrilY - 2, duration: 180, yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
    });
}

function pararseSobreVehiculo(jugadorRef, vehiculo) {
    if (!vehiculo || !vehiculo.active) return;
    // Pisar el techo
    if (jugadorRef.body.velocity.y >= 0 && jugadorRef.y <= vehiculo.body.top + 25) {
        jugadorRef.y = vehiculo.body.top;
        jugadorRef.setVelocityY(0);
        jugadorRef.body.allowGravity = false;
        estaSaltando = false;
        vehiculoApoyado = vehiculo;
    }
}

function choqueVehiculoFrontal(jugadorRef, vehiculo) {
    // Si choca de frente estando en su mismo carril y el vehiculo viene rápido
    if (!vehiculoApoyado && Math.abs(carrilActual - vehiculo.y) < 35 && !vehiculo.averiado) {
        recibirDanioJugador(jugadorRef.scene);
    }
}

function actualizarColectivos(escena) {
    const scrollX = escena.cameras.main.scrollX;
    colectivos.children.iterate((bus) => {
        if (!bus || !bus.active) return;
        bus.setVelocityX(bus.velocidadX);

        if (bus.x < scrollX - 600 || bus.x > scrollX + ANCHO_VISTA + 800) {
            bus.destroy();
        }
    });
}

function impactarVehiculo(proyectil, vehiculo) {
    if (!proyectil || !proyectil.active || !vehiculo || !vehiculo.active || vehiculo.averiado || !vehiculo.dinamico) return;
    if (Math.abs(proyectil.y - (vehiculo.y - vehiculo.displayHeight / 2)) > 75) return;

    let danio = proyectil.danio || 1;
    vehiculo.vida -= danio;
    proyectil.destroy();
    vehiculo.setTint(0xff2222);
    AudioSFX.play('golpe');

    vehiculo.scene.time.delayedCall(120, () => {
        if (vehiculo && vehiculo.active && !vehiculo.averiado) vehiculo.clearTint();
    });

    if (vehiculo.vida <= 0) {
        vehiculo.averiado = true; // Se detiene
        vehiculo.velocidadX = 0;
        vehiculo.setTint(0x666666);
        puntos += 150;
        actualizarHUD();

        let txtAveriado = vehiculo.scene.add.text(vehiculo.x, vehiculo.y - 130, '¡DETENIDO!', {
            fontSize: '14px', fontFamily: 'Arial Black', fill: '#ffaa00', stroke: '#000000', strokeThickness: 3
        }).setOrigin(0.5).setDepth(100);

        vehiculo.scene.tweens.add({
            targets: txtAveriado, y: txtAveriado.y - 30, alpha: 0, duration: 800, onComplete: () => txtAveriado.destroy()
        });
    }
}

// =============================================================================
// RECOLECCIÓN
// =============================================================================
function crearSangucheMilanesa(escena, x, carrilY) {
    let sanguche = potenciadores.create(x, carrilY, 'sanguche');
    sanguche.setScale(0.25);
    sanguche.body.allowGravity = false;
    sanguche.tipo = 'SANGUCHE';
    escena.tweens.add({ targets: sanguche, scaleX: 0.28, scaleY: 0.28, duration: 400, yoyo: true, repeat: -1 });
}

function recolectarPotenciador(jugadorRef, item) {
    if (!item || !item.active) return;
    if (Math.abs(carrilActual - item.y) > 30) return;

    if (item.tipo === 'SANGUCHE') {
        salud = MAX_SALUD;
        vidas = Math.min(3, vidas + 1);
        AudioSFX.play('sanguche');
        activarModoSanguchazo(jugadorRef.scene);
        mostrarMensaje(jugadorRef.scene, '¡SÁNGUCHE DE MILANGA COMPLETO!\nSalud al 100% y Cabezazo (C) Disponible');
        item.destroy();
    } else if (item.tipo === 'CASCOTES') {
        recolectando = true;
        jugador.setVelocityX(0);
        jugador.anims.play('juntar_cascotes', true);
        item.destroy();

        // [Nota para mí: Bloqueo al jugador un instante y pongo la animación al agarrar los cascotes]
        jugadorRef.scene.time.delayedCall(500, () => {
            armaActual = 'CASCOTE';
            municion = (municion || 0) + 20;
            AudioSFX.play('achilata');
            mostrarMensaje(jugadorRef.scene, '¡ENCONTRASTE CASCOTES!\nAhora tienes munición pesada (+20)');
            recolectando = false;
            actualizarHUD();
        });
    }
}

function activarModoSanguchazo(escena) {
    modoSanguchazo = true;
    textoEspecial.setText('¡FURIA MILANESA (CABEZAZO CON C)!');
    jugador.setTint(0xffd700);
    window.dispatchEvent(new CustomEvent('modo-sanguchazo', { detail: { activo: true } }));
    escena.time.delayedCall(10000, () => {
        modoSanguchazo = false;
        textoEspecial.setText('');
        if (jugador && jugador.active && !esInvulnerable) jugador.clearTint();
        window.dispatchEvent(new CustomEvent('modo-sanguchazo', { detail: { activo: false } }));
    });
}

// =============================================================================
// CABEZAZO (NUEVA ANIMACIÓN)
// =============================================================================
function ejecutarCabezazo(escena) {
    cabezazoActivo = true;
    let dir = jugador.flipX ? -1 : 1;

    // [Nota para mí: Ejecuto la animación real del cabezazo usando los sprites solicitados]
    jugador.anims.play('cabezazo_anim', true);
    jugador.setVelocityX(dir * 550);
    AudioSFX.play('cabezazo');

    escena.time.delayedCall(250, () => {
        if (!jugador || !jugador.active) return;

        const rango = 80;
        const dañarEnRango = (grupo, puntosBase) => {
            grupo.children.iterate(e => {
                if (e && e.active && Math.abs(e.x - jugador.x) < rango && Math.abs(carrilActual - e.y) < 35) {
                    e.destroy();
                    puntos += puntosBase;
                }
            });
        };
        dañarEnRango(hipsters, 75);
        dañarEnRango(agentes, 150);
        dañarEnRango(grandotes, 300);

        if (jefe && jefe.active && !jefeInvulnerable && jefeActivo &&
            Math.abs(jefe.x - jugador.x) < rango && Math.abs(carrilActual - jefe.y) < 35) {
            impactarJefe({ destroy: () => { }, danio: 5, y: jugador.y, active: true }, jefe);
        }

        actualizarHUD();
        cabezazoActivo = false;
    });
}

// =============================================================================
// OLEADAS Y SPAWN 
// =============================================================================
function verificarProgresionOleadas(escena) {
    const oleadas = [
        {
            id: 1, triggerX: 900, ejecutar: () => {
                lanzarColectivoDinámico(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 300, 'exprebus');
                spawnEnemigo(escena, 'HIPSTER', 0, 'derecha');
                spawnEnemigo(escena, 'HIPSTER', 350, 'derecha');
            }
        },
        {
            id: 2, triggerX: 2200, ejecutar: () => {
                lanzarColectivoDinámico(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 300, 'tesa');
                spawnEnemigo(escena, 'AGENTE', 0, 'derecha');
                spawnEnemigo(escena, 'HIPSTER', 400, 'izquierda');
            }
        },
        {
            id: 3, triggerX: 3500, ejecutar: () => {
                lanzarColectivoDinámico(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 300, 'camion_limones');
                spawnEnemigo(escena, 'AGENTE', 0, 'derecha');
                spawnEnemigo(escena, 'AGENTE', 450, 'izquierda');
            }
        },
        {
            id: 4, triggerX: 4700, ejecutar: () => {
                lanzarColectivoDinámico(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 300, 'exprebus');
                spawnEnemigo(escena, 'GRANDOTE', 0, 'izquierda');
                spawnEnemigo(escena, 'AGENTE', 450, 'derecha');
            }
        },
        {
            id: 5, triggerX: 5800, ejecutar: () => {
                lanzarColectivoDinámico(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 300, 'tesa');
                spawnEnemigo(escena, 'GRANDOTE', 0, 'derecha');
                spawnEnemigo(escena, 'AGENTE', 450, 'izquierda');
            }
        },
        {
            id: 6, triggerX: 6800, ejecutar: () => {
                lanzarColectivoDinámico(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 300, 'camion_limones');
                spawnEnemigo(escena, 'GRANDOTE', 0, 'derecha');
                spawnEnemigo(escena, 'GRANDOTE', 550, 'izquierda');
            }
        }
    ];

    oleadas.forEach(ol => {
        if (jugador.x >= ol.triggerX && !oleadasActivadas.includes(ol.id)) {
            oleadasActivadas.push(ol.id);
            ol.ejecutar();
        }
    });
}

function spawnEnemigo(escena, tipo, retrasoMs, lado) {
    escena.time.delayedCall(retrasoMs, () => {
        if (juegoTerminado) return;

        let ladoFinal = lado || (Math.random() > 0.5 ? 'derecha' : 'izquierda');
        let posX = (ladoFinal === 'derecha')
            ? escena.cameras.main.scrollX + ANCHO_VISTA + 60
            : Math.max(40, escena.cameras.main.scrollX - 60);

        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;

        if (tipo === 'HIPSTER') {
            let h = hipsters.create(posX, carril, 'hipster_agua1');
            h.setScale(0.40);
            h.tipo = 'HIPSTER';
            h.vida = 3;
            h.puntosValor = 75;
            h.invulnerable = false;
            h.estaDisparando = false;
            h.ultimoAtaque = escena.time.now + Phaser.Math.Between(800, 1600);
            h.body.allowGravity = false;
        } else if (tipo === 'AGENTE') {
            let a = agentes.create(posX, carril, 'agente_run1');
            a.setScale(0.40);
            a.tipo = 'AGENTE';
            a.vida = 5;
            a.puntosValor = 150;
            a.invulnerable = false;
            a.estaDisparando = false;
            a.ultimoDisparo = escena.time.now + Phaser.Math.Between(600, 1400);
            a.body.allowGravity = false;
        } else if (tipo === 'GRANDOTE') {
            let g = grandotes.create(posX, carril, 'grandote_run1');
            g.setScale(0.72);
            g.tipo = 'GRANDOTE';
            g.vida = 10;
            g.puntosValor = 300;
            g.invulnerable = false;
            g.atacandoCuerpoACuerpo = false;
            g.body.allowGravity = false;
        }
    });
}

// =============================================================================
// COMPORTAMIENTOS E IA DE ENEMIGOS
// =============================================================================
function actualizarIAHipsters(escena) {
    const scrollX = escena.cameras.main.scrollX;
    hipsters.children.iterate((hipster) => {
        if (!hipster || !hipster.active) return;
        if (hipster.x < scrollX - 300) { hipster.destroy(); return; }
        if (hipster.estaDisparando) return;

        let dist = Math.abs(hipster.x - jugador.x);
        let dir = (jugador.x < hipster.x) ? -1 : 1;
        hipster.setFlipX(dir > 0);

        if (dist < 650 && escena.time.now > hipster.ultimoAtaque + 2400 && Math.abs(carrilActual - hipster.y) < 40) {
            hipster.estaDisparando = true;
            hipster.setVelocityX(0);
            hipster.anims.play('hipster_lanzar', true);

            escena.time.delayedCall(300, () => {
                if (hipster && hipster.active) {
                    let botella = proyectilesEnemigos.create(hipster.x + (dir * 16), hipster.y - 6, 'botella_agua');
                    botella.setScale(0.14);
                    botella.setDepth(hipster.y + (hipster.displayHeight * 0.5));
                    botella.setVelocity(dir * 270, 0);
                    botella.velocidadGiro = dir * 16;
                }
            });

            escena.time.delayedCall(700, () => {
                if (hipster && hipster.active) {
                    hipster.ultimoAtaque = escena.time.now;
                    hipster.estaDisparando = false;
                }
            });
            return;
        }
        hipster.setVelocityX(dir * 65);
        hipster.anims.play('hipster_run', true);
    });
}

function actualizarIAAgentes(escena) {
    const scrollX = escena.cameras.main.scrollX;
    agentes.children.iterate((agente) => {
        if (!agente || !agente.active) return;
        if (agente.x < scrollX - 300) { agente.destroy(); return; }
        if (agente.estaDisparando) return;

        let dist = Math.abs(agente.x - jugador.x);
        let dir = (jugador.x < agente.x) ? -1 : 1;
        agente.setFlipX(dir > 0);

        if (dist < 700 && escena.time.now > agente.ultimoDisparo + 2600 && Math.abs(carrilActual - agente.y) < 40) {
            agente.estaDisparando = true;
            agente.setVelocityX(0);
            agente.anims.play('agente_disparar', true);

            const dispararBala = () => {
                if (agente && agente.active) {
                    let bala = proyectilesEnemigos.create(agente.x + (dir * 20), agente.y - 6, 'bala');
                    bala.setScale(0.20);
                    bala.setDepth(agente.y + (agente.displayHeight * 0.5));
                    bala.setVelocity(dir * 190, 0);
                }
            };

            escena.time.delayedCall(250, dispararBala);
            escena.time.delayedCall(560, () => {
                if (agente && agente.active) agente.anims.play('agente_disparar', true);
                dispararBala();
            });

            escena.time.delayedCall(950, () => {
                if (agente && agente.active) {
                    agente.ultimoDisparo = escena.time.now;
                    agente.estaDisparando = false;
                }
            });
            return;
        }

        if (dist > 180) {
            agente.setVelocityX(dir * 75);
            agente.anims.play('agente_run', true);
        } else {
            agente.setVelocityX(0);
            agente.anims.play('agente_run', true);
        }
    });
}

function actualizarIAGrandotes(escena) {
    const scrollX = escena.cameras.main.scrollX;
    grandotes.children.iterate((grandote) => {
        if (!grandote || !grandote.active) return;
        if (grandote.x < scrollX - 300) { grandote.destroy(); return; }
        if (grandote.atacandoCuerpoACuerpo) return;

        let dist = Math.abs(grandote.x - jugador.x);
        let dir = (jugador.x < grandote.x) ? -1 : 1;
        grandote.setFlipX(dir > 0);

        if (dist < 95 && Math.abs(carrilActual - grandote.y) < 35) {
            grandote.atacandoCuerpoACuerpo = true;
            grandote.setVelocityX(0);
            grandote.anims.play('grandote_punch', true);

            escena.time.delayedCall(300, () => {
                if (grandote && grandote.active && Math.abs(grandote.x - jugador.x) < 105 && Math.abs(carrilActual - grandote.y) < 35) {
                    recibirDanioJugador(escena);
                }
            });

            escena.time.delayedCall(650, () => {
                if (grandote && grandote.active) grandote.atacandoCuerpoACuerpo = false;
            });
            return;
        }
        grandote.setVelocityX(dir * 100);
        grandote.anims.play('grandote_run', true);
    });
}

function impactarEnemigo(proyectil, enemigo) {
    if (!proyectil || !proyectil.active || !enemigo || !enemigo.active) return;
    if (Math.abs(proyectil.y - enemigo.y) > 40) return;

    let danio = proyectil.danio || 1;
    proyectil.destroy();
    AudioSFX.play('golpe');

    if (enemigo.invulnerable) return;

    enemigo.vida -= danio;
    enemigo.invulnerable = true;
    enemigo.setTint(0xff3333);

    enemigo.scene.time.delayedCall(160, () => {
        if (enemigo && enemigo.active) {
            enemigo.clearTint();
            enemigo.invulnerable = false;
        }
    });

    if (enemigo.vida <= 0) {
        puntos += enemigo.puntosValor || 50;
        enemigo.destroy();
        actualizarHUD();
    }
}

// =============================================================================
// DISPARO DEL CIRUJA
// =============================================================================
function intentarDisparo(escena) {
    if (armaActual === 'NINGUNA') return;
    if (armaActual === 'CASCOTE' && municion <= 0) {
        armaActual = 'NARANJA';
        actualizarHUD();
    }

    disparando = true;
    let dirX = jugador.flipX ? -1 : 1;
    let esCascote = (armaActual === 'CASCOTE');
    let velocidadProyectil = esCascote ? 700 : 560;
    let spriteProyectil = esCascote ? 'cascote' : 'naranja';
    let escalaProyectil = esCascote ? 0.14 : 0.095;

    jugador.anims.play(esCascote ? 'disparar_cascote' : 'disparar_naranja', true);
    AudioSFX.play(esCascote ? 'disparo_cascote' : 'disparo_naranja');

    let spawnX = jugador.x + (dirX * 8);
    let spawnY = jugador.y - 4;
    let proyectil = proyectilesJugador.create(spawnX, spawnY, spriteProyectil);
    proyectil.setScale(escalaProyectil);
    proyectil.setDepth(carrilActual + (jugador.displayHeight * 0.5));
    proyectil.setVelocity(dirX * velocidadProyectil, 0);
    proyectil.velocidadGiro = (dirX !== 0 ? dirX : 1) * 20;
    proyectil.danio = esCascote ? 3 : 1;

    if (esCascote) {
        municion -= 1;
        if (municion <= 0) {
            armaActual = 'NARANJA';
            mostrarMensaje(escena, '¡Te quedaste sin cascotes!\nVuelves a las naranjas');
        }
    }

    actualizarHUD();
    escena.time.delayedCall(150, () => { disparando = false; });
}

// =============================================================================
// JEFE FINAL (PALERMITANO MALVADO)
// =============================================================================
function ejecutarRutinaJefe() {
    if (!jefe || !jefe.active || !jefeActivo || jefeAtacando || juegoTerminado) return;
    jefeAtacando = true;

    let mirarIzquierda = (jugador.x < jefe.x);
    jefe.setFlipX(!mirarIzquierda);
    let dir = mirarIzquierda ? -1 : 1;

    let ataqueAleatorio = Math.random();

    if (ataqueAleatorio < 0.50) {
        jefe.anims.play('boss_cofee', true);
        jefe.setVelocityX(0);
        this.time.delayedCall(300, () => {
            if (jefe && jefe.active) lanzarVasoCafe(this, jefe.x + (dir * 30), jefe.y - 10, dir * 360, 0);
        });
        this.time.delayedCall(850, () => {
            if (jefe && jefe.active) {
                jefe.anims.play('boss_joke', true);
                jefeAtacando = false;
            }
        });
    } else {
        jefe.anims.play('boss_run', true);
        jefe.setVelocityX(dir * 220);

        this.time.delayedCall(450, () => {
            if (jefe && jefe.active) {
                jefe.setVelocityX(0);
                jefe.anims.play('boss_cofee', true);
                lanzarVasoCafe(this, jefe.x + (dir * 30), jefe.y - 10, dir * 420, 0);
            }
        });

        this.time.delayedCall(800, () => {
            if (jefe && jefe.active) {
                let distRetorno = 7650 - jefe.x;
                if (Math.abs(distRetorno) > 50) {
                    jefe.setVelocityX(Math.sign(distRetorno) * 160);
                    jefe.setFlipX(distRetorno < 0);
                    jefe.anims.play('boss_run', true);
                }
            }
        });

        this.time.delayedCall(1300, () => {
            if (jefe && jefe.active) {
                jefe.setVelocityX(0);
                jefe.anims.play('boss_joke', true);
                jefeAtacando = false;
            }
        });
    }
}

function lanzarVasoCafe(escena, x, y, velX, velY) {
    let cafe = proyectilesEnemigos.create(x, y, 'cofee');
    cafe.setScale(0.25);
    cafe.setDepth(y + 20);
    cafe.setVelocity(velX, velY);
    cafe.velocidadGiro = -16;
}

function impactarJefe(proyectil, jefeRef) {
    if (!proyectil || !proyectil.active || !jefeRef || !jefeRef.active) return;
    if (Math.abs(proyectil.y - jefeRef.y) > 50) return;

    let danio = proyectil.danio || 1;
    proyectil.destroy();
    AudioSFX.play('golpe');

    if (jefeInvulnerable || !jefeActivo) return;

    vidaJefe -= danio;
    puntos += 60 * danio;
    actualizarHUD();
    actualizarBarraJefe();

    jefeInvulnerable = true;
    jefeRef.setTint(0xff3333);

    jefeRef.scene.time.delayedCall(180, () => {
        if (jefeRef && jefeRef.active) {
            jefeRef.clearTint();
            jefeInvulnerable = false;
        }
    });

    if (vidaJefe <= 0) derrotarJefe(jefeRef.scene);
}

function actualizarBarraJefe() {
    const bloques = Math.max(0, Math.ceil(vidaJefe / 4));
    textoVidaJefe.setText('PALERMITANO MALVADO: ' + '█'.repeat(bloques));
}

function derrotarJefe(escena) {
    puntos += 1500;
    actualizarHUD();
    textoVidaJefe.setText('¡RECETA SALVADA!');
    AudioSFX.play('victoria');

    escena.tweens.add({
        targets: jefe, angle: 180, y: jefe.y - 80, alpha: 0, duration: 900,
        onComplete: () => {
            if (jefe) jefe.destroy();
            mostrarMensaje(escena, '¡HAS VENCIDO AL PALERMITANO!\nAvanza a la meta');
            if (jugador && jugador.x >= 7750) llegarALaMeta(jugador, metaFinal);
        }
    });
}

function interaccionJugadorEnemigo(jugadorRef, enemigo) {
    if (!enemigo || !enemigo.active) return;
    if (Math.abs(carrilActual - enemigo.y) > 30) return;

    if (modoSanguchazo) {
        enemigo.destroy();
        puntos += 100;
        AudioSFX.play('golpe');
        actualizarHUD();
        return;
    }
    recibirDanioJugador(jugadorRef.scene);
}

function interaccionJugadorJefe(jugadorRef, jefeRef) {
    if (!jefeRef || !jefeRef.active) return;
    if (Math.abs(carrilActual - jefeRef.y) > 35) return;

    if (modoSanguchazo) {
        impactarJefe({ destroy: () => { }, danio: 3, y: jugadorRef.y, active: true }, jefeRef);
        return;
    }
    recibirDanioJugador(jugadorRef.scene);
}

function impactarJugadorConProyectilEnemigo(jugadorRef, proyectil) {
    if (!proyectil || !proyectil.active) return;
    if (Math.abs(carrilActual - proyectil.y) > 30) return;
    proyectil.destroy();
    recibirDanioJugador(jugadorRef.scene);
}

// =============================================================================
// SALUD Y DAÑO
// =============================================================================
function recibirDanioJugador(escena) {
    if (esInvulnerable || juegoTerminado) return;
    salud -= 1;
    AudioSFX.play('danio');

    if (salud <= 0) {
        vidas -= 1;
        salud = MAX_SALUD;
    }
    actualizarHUD();

    if (vidas <= 0) {
        mostrarGameOver(escena);
    } else {
        esInvulnerable = true;
        jugador.setVelocityX(jugador.flipX ? 160 : -160);

        let parpadeos = 0;
        escena.time.addEvent({
            delay: 100, repeat: 7, callback: () => {
                if (jugador && jugador.active) {
                    jugador.alpha = (jugador.alpha === 1) ? 0.3 : 1;
                    parpadeos++;
                    if (parpadeos >= 8) {
                        jugador.alpha = 1;
                        esInvulnerable = false;
                    }
                }
            }
        });
    }
}

function mostrarGameOver(escena) {
    juegoTerminado = true;
    jugador.setVelocity(0, 0);
    jugador.setTint(0xff2222);

    escena.add.rectangle(ANCHO_VISTA / 2, ALTO_VISTA / 2, ANCHO_VISTA, ALTO_VISTA, 0x000000, 0.85)
        .setScrollFactor(0).setDepth(300);

    escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 - 50, '¡TE LIQUIDARON EN LA RUTA!', {
        fontSize: '28px', fontFamily: 'Arial Black', fill: '#ff3333', stroke: '#000000', strokeThickness: 5, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2, 'PUNTOS: ' + puntos, {
        fontSize: '20px', fontFamily: 'Arial Black', fill: '#ffd700', stroke: '#000000', strokeThickness: 4, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    let txtReintentar = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 + 60, 'Toca la pantalla, botón de acción o ESPACIO para REINTENTAR', {
        fontSize: '15px', fontFamily: 'Arial Black', fill: '#00ffcc', stroke: '#000000', strokeThickness: 3, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    escena.tweens.add({ targets: txtReintentar, alpha: 0.3, duration: 500, yoyo: true, repeat: -1 });

    const reiniciarCallback = () => {
        window.removeEventListener('arcade-button-pressed', reiniciarCallback);
        escena.scene.restart();
    };

    escena.time.delayedCall(500, () => {
        escena.input.keyboard.once('keydown-SPACE', reiniciarCallback);
        escena.input.keyboard.once('keydown-Z', reiniciarCallback);
        escena.input.keyboard.once('keydown-X', reiniciarCallback);
        escena.input.keyboard.once('keydown-ENTER', reiniciarCallback);
        escena.input.once('pointerdown', reiniciarCallback);
        window.addEventListener('arcade-button-pressed', reiniciarCallback, { once: true });
    });
}

// =============================================================================
// INTERFAZ Y SISTEMA DE INSOLACIÓN
// =============================================================================
function recolectarEmpanada(jugadorRef, empanada) {
    if (!empanada || !empanada.active) return;
    if (Math.abs(carrilActual - empanada.y) > 25) return;
    empanada.destroy();
    puntos += 25;
    AudioSFX.play('empanada');
    actualizarHUD();
}

function recolectarAchilata(jugadorRef, achilata) {
    if (!achilata || !achilata.active) return;
    if (Math.abs(carrilActual - achilata.y) > 25) return;
    achilata.destroy();
    nivelInsolacion = Math.max(0, nivelInsolacion - 50);
    puntos += 100;
    AudioSFX.play('achilata');
    dibujarBarraInsolacion();
    actualizarHUD();
    mostrarMensaje(jugadorRef.scene, '¡QUÉ RICA ACHILATA!\nInsolación reducida');
}

function mostrarCartelAlerta(escena) {
    AudioSFX.play('alerta');
    const cartel = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 - 40, '⚠ ZONA DE MUCHO SOL ⚠\nBuscá achilatas para refrescarte', {
        fontSize: '20px', fontFamily: 'Arial Black', fill: '#ffcc00', stroke: '#000000', strokeThickness: 5, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(150).setAlpha(0).setScale(0.7);

    escena.tweens.add({
        targets: cartel, alpha: 1, scale: 1, duration: 250, ease: 'Back.easeOut', yoyo: false,
        onComplete: () => {
            escena.tweens.add({
                targets: cartel, alpha: 0, delay: 1800, duration: 500, onComplete: () => cartel.destroy()
            });
        }
    });
}

function actualizarSistemaInsolacion(escena, time) {
    if (jugador.x > 3200) {
        if (!insolacionActiva) {
            insolacionActiva = true;
            mostrarCartelAlerta(escena);
            escena.time.delayedCall(900, () => { if (solSprite) solSprite.setAlpha(1); });
            mostrarMensaje(escena, '¡EL SOL DE LA SIESTA APRIETA!\nBusca Achilatas para no insolarte');
        }

        nivelInsolacion = Math.min(100, nivelInsolacion + 0.035);
        dibujarBarraInsolacion();

        let progresoSol = nivelInsolacion / 100;
        solSprite.setScale(0.40 + (progresoSol * 0.70));
        capaTinteCalor.setAlpha(progresoSol * 0.22);

        if (nivelInsolacion >= 100 && time > tiempoUltimoDanioSol + 2000) {
            tiempoUltimoDanioSol = time;
            mostrarMensaje(escena, '¡ESTÁS INSOLADO! PIERDES ENERGÍA');
            recibirDanioJugador(escena);
        }
    }
}

function dibujarBarraInsolacion() {
    barraCalorGrafico.clear();
    if (!insolacionActiva) return;

    const x = ANCHO_VISTA - 160; const y = 95; const ancho = 120; const alto = 12;
    barraCalorGrafico.lineStyle(2, 0x000000, 1);
    barraCalorGrafico.strokeRect(x, y, ancho, alto);

    let color = (nivelInsolacion > 75) ? 0xff0000 : (nivelInsolacion > 45) ? 0xffaa00 : 0xffff00;
    barraCalorGrafico.fillStyle(color, 1);
    barraCalorGrafico.fillRect(x, y, (ancho * (nivelInsolacion / 100)), alto);
    textoCalor.setText('INSOLACIÓN: ' + Math.floor(nivelInsolacion) + '%');
}

function dibujarBarraSalud() {
    barraVidaGrafico.clear();
    const startX = 20; const startY = 40; const blockW = 28; const blockH = 12; const gap = 6;
    for (let i = 0; i < MAX_SALUD; i++) {
        barraVidaGrafico.lineStyle(2, 0x000000, 1);
        barraVidaGrafico.strokeRect(startX + (i * (blockW + gap)), startY, blockW, blockH);
        if (i < salud) {
            let color = (salud === 3) ? 0x00ff00 : (salud === 2) ? 0xffcc00 : 0xff2222;
            barraVidaGrafico.fillStyle(color, 1);
            barraVidaGrafico.fillRect(startX + (i * (blockW + gap)), startY, blockW, blockH);
        } else {
            barraVidaGrafico.fillStyle(0x333333, 0.6);
            barraVidaGrafico.fillRect(startX + (i * (blockW + gap)), startY, blockW, blockH);
        }
    }
}

function actualizarHUD() {
    textoVidas.setText('VIDAS: ' + vidas);
    dibujarBarraSalud();
    textoPuntos.setText('PUNTOS: ' + puntos);
    if (armaActual === 'NARANJA') {
        textoArma.setText('ARMA: NARANJA (∞)');
    } else if (armaActual === 'CASCOTE') {
        textoArma.setText('ARMA: CASCOTE (' + municion + ')');
    } else {
        textoArma.setText('ARMA: DESARMADO');
    }
}

function mostrarMensaje(escena, texto) {
    if (!bannerNotificacion) return;
    const scene = escena || (jugador && jugador.scene);
    if (!scene) return;

    bannerNotificacion.setText(texto);
    bannerNotificacion.setAlpha(1);
    bannerNotificacion.setScale(1);

    scene.tweens.killTweensOf(bannerNotificacion);
    scene.tweens.add({
        targets: bannerNotificacion, scaleX: 1.15, scaleY: 1.15, duration: 180, yoyo: true,
        onComplete: () => {
            scene.tweens.add({ targets: bannerNotificacion, alpha: 0, delay: 2600, duration: 600 });
        }
    });
}

function llegarALaMeta(jugadorRef, meta) {
    if (jefe && jefe.active) return;
    if (juegoTerminado) return;

    juegoTerminado = true;
    jugador.setVelocity(0, 0);
    jugador.anims.play('idle', true);
    AudioSFX.play('victoria');

    let escena = jugadorRef.scene;
    escena.add.rectangle(ANCHO_VISTA / 2, ALTO_VISTA / 2, ANCHO_VISTA, ALTO_VISTA, 0x000000, 0.85).setScrollFactor(0).setDepth(300);
    escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 - 60, '¡NIVEL 1 COMPLETADO!\n¡RECETA DE LA EMPANADA SALVADA!', {
        fontSize: '26px', fontFamily: 'Arial Black', fill: '#00ff66', stroke: '#000000', strokeThickness: 5, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);
    escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 + 10, 'PUNTOS TOTALES: ' + puntos, {
        fontSize: '22px', fontFamily: 'Arial Black', fill: '#ffd700', stroke: '#000000', strokeThickness: 4, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    let txtReiniciar = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 + 70, 'Toca la pantalla, botón de acción o ESPACIO para VOLVER A JUGAR', {
        fontSize: '15px', fontFamily: 'Arial Black', fill: '#00ffcc', stroke: '#000000', strokeThickness: 3, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    escena.tweens.add({ targets: txtReiniciar, alpha: 0.3, duration: 500, yoyo: true, repeat: -1 });

    const reiniciarCallback = () => {
        window.removeEventListener('arcade-button-pressed', reiniciarCallback);
        escena.scene.restart();
    };

    escena.time.delayedCall(500, () => {
        escena.input.keyboard.once('keydown-SPACE', reiniciarCallback);
        escena.input.keyboard.once('keydown-Z', reiniciarCallback);
        escena.input.keyboard.once('keydown-X', reiniciarCallback);
        escena.input.keyboard.once('keydown-ENTER', reiniciarCallback);
        escena.input.once('pointerdown', reiniciarCallback);
        window.addEventListener('arcade-button-pressed', reiniciarCallback, { once: true });
    });
}