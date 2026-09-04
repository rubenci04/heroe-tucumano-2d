// =============================================================================
// HÉROE TUCUMANO 2D ARCADE - ARCHIVO PRINCIPAL: main.js
// VERSIÓN CORREGIDA - Cambios aplicados (ver resumen en el chat):
// 1) Animación de cambio de carril con "saltito" en arco
// 2) Oleadas iniciales más numerosas y con spawn izquierda/derecha
// 3) Fix de profundidad (depth) para que el jugador nunca quede tapado por vehículos
// 4) Camión de limones del mismo tamaño que los colectivos
// 5) Fondo de fusión más arriba y más grande
// 6) Autos un poco más grandes
// 7) Disparo de agentes más lento y en ráfaga de 2 tiros esquivables
// 8) Enemigos aparecen de ambos lados (izquierda/derecha)
// 9) Jefe final con más vida (más difícil)
// 10) Insolación más lenta + sol crece con el nivel + cartel de alerta previo
// 11) Sistema de "cabezazo" (placeholder funcional, listo para tus sprites)
// 12) Vehículos estáticos: solo el jugador los salta/esquiva
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
let cambiandoCarril = false; // FIX #1: bloquea input mientras dura la animación de cambio de carril

// Variables del Jefe Final y Progresión
let jefe, jefeActivo = false, vidaJefe = 90, jefeInvulnerable = false, jefeAtacando = false; // FIX #9: más vida
let oleadasActivadas = [];
let arbolSaqueado = false;
let cascotesLevantados = false;
let arbolNaranjasIntro;

// Variables de Cinemática, Diálogos e Insolación
let enCinematica = true;
let pasoCinematica = 0;
let textoNarradoGlobal, cajaTextoGlobal, actoresCinematica = {};
let solSprite, barraCalorGrafico, textoCalor, capaTinteCalor;
let nivelInsolacion = 0;
let insolacionActiva = false;
let tiempoUltimoDanioSol = 0;

// Variables del "Cabezazo" (FIX #11 - poder desbloqueado por empanadas)
let empanadasRecolectadas = 0;
let cabezazoDesbloqueado = false;
let cabezazoActivo = false;
const EMPANADAS_PARA_CABEZAZO = 5;

function preload() {
    // Fondo de cielo y cerros lejanos
    this.load.image('fondo_cerros', 'assets/fondo_cerros.png');

    // Carga corregida del fondo panorámico unificado (.png)
    this.load.image('fusion_fondo', 'assets/fusion_fondos.png');

    // Suelos de la ruta
    this.load.image('suelo_ruta', 'assets/suelo_ruta.png');
    this.load.image('suelo_ruta2', 'assets/suelo_ruta2.png');

    // Props y Escenografía
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

    // Sprites de Cinemática
    this.load.image('ciruja_comiendo', 'assets/ciruja comiendo.png');
    this.load.image('campeona_empanadas', 'assets/campeona empanadas.png');
    this.load.image('secuestro_campeona', 'assets/secuestro_campeona.png');

    // Sprites del Ciruja
    this.load.image('ciruja_idle', 'assets/ciruja_idle.png');
    this.load.image('ciruja_run1', 'assets/ciruja_run1.png');
    this.load.image('ciruja_run2', 'assets/ciruja_run2.png');
    this.load.image('ciruja_run3', 'assets/ciruja_run3.png');
    this.load.image('ciruja_salto', 'assets/ciruja_salto.png');
    this.load.image('ciruja_disparo_naranja1', 'assets/ciruja_disparo_naranja1.png');
    this.load.image('ciruja_disparo_naranja2', 'assets/ciruja_disparo_naranja2.png');
    this.load.image('ciruja_disparo_cascote1', 'assets/ciruja_disparo_cascote1.png');
    this.load.image('ciruja_disparo_cascote2', 'assets/ciruja_disparo_cascote2.png');

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

    jefeActivo = false;
    vidaJefe = 90; // FIX #9: jefe más difícil
    jefeInvulnerable = false;
    jefeAtacando = false;
    oleadasActivadas = [];
    arbolSaqueado = false;
    cascotesLevantados = false;
    nivelInsolacion = 0;
    insolacionActiva = false;

    empanadasRecolectadas = 0;
    cabezazoDesbloqueado = false;
    cabezazoActivo = false;

    this.physics.world.setBounds(0, 0, ANCHO_MUNDO + 400, ALTO_VISTA);

    // =========================================================================
    // CONFIGURACIÓN DE FONDOS: CERROS LEJANOS Y FUSIÓN VISIBLE
    // FIX #5: la fusión se sube y se agranda para que no quede oculta bajo la ruta
    // =========================================================================
    fondoCerros = this.add.tileSprite(0, 0, ANCHO_VISTA, ALTO_VISTA, 'fondo_cerros')
        .setOrigin(0, 0).setScrollFactor(0).setDepth(0);

    // Montaje del lienzo fusionado panorámico (más arriba y más grande)
    fondoUnificado = this.add.image(0, -70, 'fusion_fondo')
        .setOrigin(0, 0)
        .setDisplaySize(ANCHO_MUNDO, ALTO_VISTA + 90)
        .setDepth(1.2);

    // Suelos de los dos carriles
    sueloRuta = this.add.tileSprite(0, Y_ESCENARIO - 20, ANCHO_VISTA, 160, 'suelo_ruta').setOrigin(0, 0).setScrollFactor(0).setDepth(1.5);
    sueloRuta2 = this.add.tileSprite(0, Y_ESCENARIO + 85, ANCHO_VISTA, 160, 'suelo_ruta2').setOrigin(0, 0).setScrollFactor(0).setDepth(1.6);

    // Escenografía Famaillá
    this.add.image(130, Y_ESCENARIO, 'cartel_famailla').setOrigin(0.5, 1).setScale(1.10).setDepth(2);
    this.add.image(350, Y_ESCENARIO, 'gruta_virgen').setOrigin(0.5, 1).setScale(0.72).setDepth(2);

    // Naranjo interactivo pulsante
    arbolNaranjasIntro = this.add.image(520, Y_ESCENARIO, 'arbol_naranjas').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    this.tweens.add({
        targets: arbolNaranjasIntro,
        scaleX: 0.92,
        scaleY: 0.92,
        duration: 550,
        yoyo: true,
        repeat: -1,
        ease: 'Sine.easeInOut'
    });

    // Palmeras en Famaillá
    this.add.image(680, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);
    this.add.image(880, Y_ESCENARIO, 'kiosco_coca').setOrigin(0.5, 1).setScale(1.05).setDepth(2);
    this.add.image(1150, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);

    // Paradas de colectivos y naranjos distribuidos
    [2100, 3600, 4800, 6100, 7100].forEach(px => {
        this.add.image(px, Y_ESCENARIO, 'parada_colectivo').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
        this.add.image(px + 320, Y_ESCENARIO, 'arbol_naranjas').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    });

    // Postes de luz reubicados en laterales libres
    const posicionesPostes = [1000, 1350, 1850, 2500, 3200, 3950, 4500, 5200, 5800, 6450, 7400];
    posicionesPostes.forEach(px => {
        this.add.image(px, Y_ESCENARIO, 'poste_luz').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    });

    // =========================================================================
    // ANIMACIONES
    // =========================================================================
    if (!this.anims.exists('correr')) {
        this.anims.create({ key: 'correr', frames: [{ key: 'ciruja_run1' }, { key: 'ciruja_run2' }, { key: 'ciruja_run3' }], frameRate: 12, repeat: -1 });
        this.anims.create({ key: 'idle', frames: [{ key: 'ciruja_idle' }], frameRate: 1 });
        this.anims.create({ key: 'salto', frames: [{ key: 'ciruja_salto' }], frameRate: 1 });
        this.anims.create({ key: 'disparar_naranja', frames: [{ key: 'ciruja_disparo_naranja1' }, { key: 'ciruja_disparo_naranja2' }], frameRate: 14, repeat: 0 });
        this.anims.create({ key: 'disparar_cascote', frames: [{ key: 'ciruja_disparo_cascote1' }, { key: 'ciruja_disparo_cascote2' }], frameRate: 14, repeat: 0 });

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

    // Colisiones con vehículos: plataformas y daño frontal
    this.physics.add.collider(jugador, autosRuta, pararseSobreVehiculo, null, this);
    this.physics.add.collider(jugador, colectivos, pararseSobreVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, colectivos, impactarVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, autosRuta, impactarVehiculo, null, this);

    // FIX #12: vehículos estáticos (velocidad 0) - el jugador es quien los esquiva/salta
    // FIX #4: camión de limones ahora con la escala de los colectivos (2.35) para que se vea del mismo porte
    crearAutoEnRuta(this, 1900, CARRIL_SUPERIOR_Y, 'auto1', 0, 0.95);
    crearAutoEnRuta(this, 3100, CARRIL_INFERIOR_Y, 'camion_limones', 0, 2.35);
    crearAutoEnRuta(this, 5000, CARRIL_SUPERIOR_Y, 'auto2', 0, 0.95);
    crearAutoEnRuta(this, 6700, CARRIL_INFERIOR_Y, 'auto3', 0, 0.95);

    // Jefe Palermitano Malvado esperando en el Ingenio
    jefe = this.physics.add.sprite(7650, CARRIL_INFERIOR_Y, 'final_boss_joke1');
    jefe.setScale(0.78);
    jefe.setCollideWorldBounds(true);
    jefe.body.allowGravity = false;
    jefe.anims.play('boss_joke', true);

    // Empanadas
    empanadas = this.physics.add.group();
    [240, 750, 1350, 2000, 2700, 3400, 4100, 4900, 5600, 6300, 7000, 7500].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let emp = empanadas.create(posX, carril, 'empanada');
        emp.setScale(0.14);
        emp.body.allowGravity = false;
        if (emp.postFX && emp.postFX.addGlow) {
            emp.postFX.addGlow(0xffd700, 2, 0, false);
        }
    });

    // Achilatas (FIX #10: una queda pegada al arranque de la insolación, en x=3200, bien visible)
    [3200, 3600, 4300, 5400, 6500, 7200].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let ach = achilatas.create(posX, carril, 'achilata');
        ach.setScale(0.24);
        ach.body.allowGravity = false;
        if (ach.postFX && ach.postFX.addGlow) {
            ach.postFX.addGlow(0xff00ff, 2, 0, false);
        }
    });

    // Montañas de cascotes con latido
    potenciadores = this.physics.add.group();
    let montaña1 = potenciadores.create(1450, CARRIL_SUPERIOR_Y, 'montaña_cascote');
    montaña1.setScale(0.65);
    montaña1.body.allowGravity = false;
    montaña1.tipo = 'CASCOTES';
    this.tweens.add({ targets: montaña1, scaleX: 0.70, scaleY: 0.70, duration: 500, yoyo: true, repeat: -1 });

    let montaña2 = potenciadores.create(4400, CARRIL_SUPERIOR_Y, 'montaña_cascote');
    montaña2.setScale(0.65);
    montaña2.body.allowGravity = false;
    montaña2.tipo = 'CASCOTES';
    this.tweens.add({ targets: montaña2, scaleX: 0.70, scaleY: 0.70, duration: 500, yoyo: true, repeat: -1 });

    // Dos Sánguches de Milanesa en el trayecto
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
    teclaC = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.C); // FIX #11: tecla del cabezazo

    this.time.addEvent({ delay: 2200, callback: ejecutarRutinaJefe, callbackScope: this, loop: true });

    // Habilitar audio al primer clic o pulsación
    this.input.once('pointerdown', () => AudioSFX.init());
    this.input.keyboard.once('keydown', () => AudioSFX.init());

    iniciarCinematicaInteractiva(this);
}

function update(time, delta) {
    if (!jugador.active || juegoTerminado) return;

    // Scroll Parallax sincronizado
    fondoCerros.tilePositionX = this.cameras.main.scrollX * 0.05;
    sueloRuta.tilePositionX = this.cameras.main.scrollX * 1.0;
    sueloRuta2.tilePositionX = this.cameras.main.scrollX * 1.0;

    // Gestión interactiva de la cinemática con tecla Z, X, Espacio, Enter o clic
    if (enCinematica) {
        if (Phaser.Input.Keyboard.JustDown(teclaZ) ||
            Phaser.Input.Keyboard.JustDown(teclaX) ||
            Phaser.Input.Keyboard.JustDown(cursores.space) ||
            Phaser.Input.Keyboard.JustDown(teclaEnter)) {
            avanzarCinematica(this);
        }
        return;
    }

    verificarProgresionOleadas(this);
    actualizarSistemaInsolacion(this, time);

    const velocidadBase = modoSanguchazo ? 330 : 230;

    // Movimiento horizontal en X
    if (cursores.left.isDown) {
        jugador.setVelocityX(-velocidadBase);
        jugador.setFlipX(true);
        if (!estaSaltando && !disparando && !cambiandoCarril) jugador.anims.play('correr', true);
    } else if (cursores.right.isDown) {
        jugador.setVelocityX(velocidadBase);
        jugador.setFlipX(false);
        if (!estaSaltando && !disparando && !cambiandoCarril) jugador.anims.play('correr', true);
    } else {
        jugador.setVelocityX(0);
        if (!estaSaltando && !disparando && !cambiandoCarril) jugador.anims.play('idle', true);
    }

    // =========================================================================
    // SALTO, CARRILES Y PLATAFORMAS EN VEHÍCULOS
    // =========================================================================
    if (!estaSaltando) {
        // Si estamos sobre el techo de un vehículo, comprobar que sigamos encima
        if (vehiculoApoyado) {
            let medioAncho = (vehiculoApoyado.displayWidth * 0.5) + 15;
            let fueraDelVehiculo = !vehiculoApoyado.active || Math.abs(jugador.x - vehiculoApoyado.x) > medioAncho;

            if (fueraDelVehiculo) {
                vehiculoApoyado = null;
                if (jugador.y < carrilActual) {
                    estaSaltando = true;
                    jugador.body.allowGravity = true;
                }
            }
            // Como los vehículos ahora son estáticos (FIX #12) no hace falta
            // acompañar ningún desplazamiento horizontal del vehículo.
        } else if (!cambiandoCarril) {
            // En el suelo normal
            jugador.body.allowGravity = false;
            jugador.setVelocityY(0);

            // FIX #1: Cambio de carril animado con un "saltito" en vez de teletransporte
            if (Phaser.Input.Keyboard.JustDown(cursores.up) && carrilActual === CARRIL_INFERIOR_Y) {
                cambiarDeCarril(this, CARRIL_SUPERIOR_Y);
            } else if (Phaser.Input.Keyboard.JustDown(cursores.down) && carrilActual === CARRIL_SUPERIOR_Y) {
                cambiarDeCarril(this, CARRIL_INFERIOR_Y);
            }
        }

        // Salto con barra espaciadora
        if (Phaser.Input.Keyboard.JustDown(cursores.space) && !cambiandoCarril) {
            estaSaltando = true;
            vehiculoApoyado = null;
            tiempoInicioSalto = time;
            jugador.body.allowGravity = true;
            jugador.setVelocityY(-580);
            AudioSFX.play('salto');
            if (!disparando) jugador.anims.play('salto', true);
        }
    } else {
        // En el aire: cae por gravedad hacia su carril
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

        if (cursores.space.isUp && jugador.body.velocity.y < -120) {
            jugador.setVelocityY(jugador.body.velocity.y * 0.50);
        }
    }

    // Disparo
    if (teclaZ.isDown || teclaX.isDown) {
        if (!disparoPresionado) {
            intentarDisparo(this);
            disparoPresionado = true;
        }
    } else {
        disparoPresionado = false;
    }

    // FIX #11: Cabezazo (poder desbloqueado por empanadas)
    if (cabezazoDesbloqueado && !cabezazoActivo && Phaser.Input.Keyboard.JustDown(teclaC) && !estaSaltando && !cambiandoCarril) {
        ejecutarCabezazo(this);
    }

    actualizarColectivos(this);
    actualizarAutosRuta(this);
    actualizarIAHipsters(this);
    actualizarIAAgentes(this);
    actualizarIAGrandotes(this);

    // =========================================================================
    // FIX #3: Profundidad (z-index) dinámica y correcta
    // - Todos los vehículos (colectivos incluidos, antes no se actualizaban)
    //   ahora recalculan su depth cuadro a cuadro según su Y real.
    // - El jugador usa su Y real (no el carril lógico) para el cálculo normal,
    //   pero si está parado sobre un vehículo, se fuerza su depth por encima
    //   del vehículo para que nunca quede "tapado" por él.
    // =========================================================================
    if (vehiculoApoyado && vehiculoApoyado.active) {
        jugador.setDepth(vehiculoApoyado.depth + 1);
    } else {
        jugador.setDepth(jugador.y + (jugador.displayHeight * 0.5));
    }

    hipsters.children.iterate(e => { if (e && e.active) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    agentes.children.iterate(e => { if (e && e.active) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    grandotes.children.iterate(e => { if (e && e.active) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    autosRuta.children.iterate(a => { if (a && a.active) a.setDepth(a.y); });
    colectivos.children.iterate(b => { if (b && b.active) b.setDepth(b.y); }); // FIX #3: antes faltaba esta línea
    empanadas.children.iterate(e => { if (e && e.active) e.setDepth(e.y); });
    achilatas.children.iterate(e => { if (e && e.active) e.setDepth(e.y); });
    potenciadores.children.iterate(e => { if (e && e.active) e.setDepth(e.y); });
    if (jefe && jefe.active) jefe.setDepth(jefe.y + (jefe.displayHeight * 0.5));

    // Limpieza de proyectiles fuera de pantalla
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

    // Activar combate con el Jefe al llegar a su zona
    if (jefe && jefe.active && !jefeActivo && jugador.x > 7300) {
        jefeActivo = true;
        actualizarBarraJefe();
        mostrarMensaje(this, '¡EL PALERMITANO MALVADO ESTÁ EN EL INGENIO!\n¡Derrótalo para salvar las empanadas!');
    }
}

// =============================================================================
// FIX #1: CAMBIO DE CARRIL ANIMADO ("SALTITO")
// =============================================================================
function cambiarDeCarril(escena, nuevoCarril) {
    cambiandoCarril = true;
    let carrilOrigen = carrilActual;
    carrilActual = nuevoCarril;

    if (!disparando) jugador.anims.play('salto', true);
    AudioSFX.play('salto');

    // Pequeño arco: primero sube un poco, después cae al nuevo carril
    escena.tweens.add({
        targets: jugador,
        y: carrilOrigen - 16,
        duration: 90,
        ease: 'Sine.easeOut',
        onComplete: () => {
            if (!jugador || !jugador.active) return;
            escena.tweens.add({
                targets: jugador,
                y: nuevoCarril,
                duration: 140,
                ease: 'Sine.easeIn',
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

    textoNarradoGlobal = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA - 60, 'FAMAILLÁ, CAPITAL DE LA EMPANADA.\nEL CIRUJA DISFRUTA DE UN MEDIODÍA DE PAZ...\n(Presiona Z, Espacio o Clic para continuar)', {
        fontSize: '14px', fontFamily: 'Arial Black', fill: '#00ffcc', align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(201);

    escena.cameras.main.pan(400, ALTO_VISTA / 2, 1800, 'Sine.easeInOut');

    // Permitir clic para avanzar
    escena.input.once('pointerdown', () => {
        if (enCinematica) avanzarCinematica(escena);
    });
}

function avanzarCinematica(escena) {
    pasoCinematica++;

    if (pasoCinematica === 1) {
        escena.cameras.main.pan(300, ALTO_VISTA / 2, 800, 'Sine.easeInOut');
        textoNarradoGlobal.setText('¡ATAQUE SORPRESA!\nLOS AGENTES ATRAPAN A LA CAMPEONA DE LA EMPANADA...\n(Presiona Z para continuar)');
        textoNarradoGlobal.setFill('#ff3333');

        if (actoresCinematica.campeona) actoresCinematica.campeona.destroy();
        actoresCinematica.raptores = escena.add.image(290, CARRIL_SUPERIOR_Y - 5, 'secuestro_campeona').setScale(0.85).setDepth(55);
        actoresCinematica.jefeIntro = escena.add.sprite(200, CARRIL_SUPERIOR_Y - 10, 'final_boss_joke1').setScale(0.75).setDepth(56);
        actoresCinematica.jefeIntro.anims.play('boss_joke', true);

        AudioSFX.play('danio');
    } else if (pasoCinematica === 2) {
        textoNarradoGlobal.setText('PALERMITANO MALVADO: "¡LLEVENLA AL INGENIO!\n¡VAMOS A SERVIR LA EMPANADA DECONSTRUIDA EN FRASCO!"\n(Presiona Z para salir a perseguirlos)');
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
// PLATAFORMAS Y VEHÍCULOS (FIX #4, #6, #12)
// =============================================================================
function crearAutoEnRuta(escena, x, carrilY, spriteKey, velX, escala) {
    let escalaFinal = (escala !== undefined) ? escala : 0.95; // FIX #6: autos un poco más grandes
    let auto = autosRuta.create(x, carrilY + 4, spriteKey);
    auto.setOrigin(0.5, 1);
    auto.setScale(escalaFinal);
    auto.setDepth(carrilY);
    auto.vida = (escalaFinal >= 2) ? 10 : 4; // el camión de limones, al ser del porte de un bus, aguanta más
    auto.velocidadX = velX; // FIX #12: se pasa 0 desde los llamados -> vehículo estático
    auto.averiado = false;
    auto.setImmovable(true);
    auto.body.allowGravity = false;

    // Dimensiones de colisión proporcionales sin duplicar escala
    let ancho = auto.width * 0.85;
    let alto = auto.height * 0.75;
    auto.body.setSize(ancho, alto);
    auto.body.setOffset((auto.width - ancho) / 2, auto.height - alto);
}

function lanzarColectivo(escena, x, spriteKey, velocidad) {
    let carrilY = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y + 15 : CARRIL_INFERIOR_Y + 10;
    let bus = colectivos.create(x, carrilY, spriteKey);
    bus.setOrigin(0.5, 1);
    bus.setScale(2.35);
    bus.setDepth(carrilY);
    bus.vida = 10;
    bus.velocidadX = velocidad; // FIX #12: se pasa 0 -> vehículo estático, el jugador lo esquiva/salta
    bus.averiado = false;
    bus.setImmovable(true);
    bus.body.allowGravity = false;

    // Dimensiones de colisión proporcionales
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

    // Si viene cayendo desde arriba del techo, se apoya sólidamente como plataforma
    if (jugadorRef.body.velocity.y >= 0 && jugadorRef.y <= vehiculo.body.top + 20) {
        jugadorRef.y = vehiculo.body.top;
        jugadorRef.setVelocityY(0);
        jugadorRef.body.allowGravity = false;
        estaSaltando = false;
        vehiculoApoyado = vehiculo;
        return;
    }

    // Si choca de frente estando en su mismo carril, recibe daño (salvo en modo sánguche)
    if (Math.abs(carrilActual - vehiculo.y) < 35 && !vehiculo.averiado) {
        if (modoSanguchazo) {
            vehiculo.vida -= 3;
            vehiculo.setTint(0xff2222);
            jugadorRef.scene.time.delayedCall(120, () => {
                if (vehiculo && vehiculo.active && !vehiculo.averiado) vehiculo.clearTint();
            });
            if (vehiculo.vida <= 0) {
                vehiculo.averiado = true;
                vehiculo.setTint(0x666666);
                puntos += 250;
                actualizarHUD();
            }
        } else {
            recibirDanioJugador(jugadorRef.scene);
        }
    }
}

function actualizarColectivos(escena) {
    const scrollX = escena.cameras.main.scrollX;
    colectivos.children.iterate((bus) => {
        if (!bus || !bus.active) return;
        bus.setVelocityX(!bus.averiado ? bus.velocidadX : 0);

        // Limpieza de colectivos que quedan muy atrás
        if (bus.x < scrollX - 500) {
            bus.destroy();
        }
    });
}

function actualizarAutosRuta(escena) {
    const scrollX = escena.cameras.main.scrollX;
    autosRuta.children.iterate((auto) => {
        if (!auto || !auto.active) return;
        auto.setVelocityX(!auto.averiado ? auto.velocidadX : 0);

        // Limpieza de autos que quedan muy atrás
        if (auto.x < scrollX - 500) {
            auto.destroy();
        }
    });
}

function impactarVehiculo(proyectil, vehiculo) {
    if (!proyectil || !proyectil.active || !vehiculo || !vehiculo.active || vehiculo.averiado) return;
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
        vehiculo.averiado = true;
        vehiculo.setTint(0x666666);
        puntos += 250;
        actualizarHUD();

        let txtAveriado = vehiculo.scene.add.text(vehiculo.x, vehiculo.y - 130, '¡AVERÍA TOTAL!', {
            fontSize: '14px', fontFamily: 'Arial Black', fill: '#ffaa00', stroke: '#000000', strokeThickness: 3
        }).setOrigin(0.5).setDepth(100);

        vehiculo.scene.tweens.add({
            targets: txtAveriado, y: txtAveriado.y - 30, alpha: 0, duration: 800, onComplete: () => txtAveriado.destroy()
        });
    }
}

// =============================================================================
// SÁNGUCHE DE MILANESA (CURA TOTAL + FURIA)
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
        mostrarMensaje(jugadorRef.scene, '¡SÁNGUCHE DE MILANGA COMPLETO!\nSalud al 100% y Furia Activada');
    } else if (item.tipo === 'CASCOTES') {
        cascotesLevantados = true;
        armaActual = 'CASCOTE';
        municion = (municion || 0) + 20;
        AudioSFX.play('achilata');
        mostrarMensaje(jugadorRef.scene, '¡ENCONTRASTE UN MONTÓN DE CASCOTES!\nAhora tienes munición pesada (+20)');
    }
    actualizarHUD();
    item.destroy();
}

function activarModoSanguchazo(escena) {
    modoSanguchazo = true;
    textoEspecial.setText('¡FURIA DE MILANGA ACTIVADA!');
    jugador.setTint(0xffd700);
    escena.time.delayedCall(8000, () => {
        modoSanguchazo = false;
        textoEspecial.setText('');
        if (jugador && jugador.active && !esInvulnerable) jugador.clearTint();
    });
}

// =============================================================================
// FIX #11: CABEZAZO - poder desbloqueado al juntar empanadas
// Placeholder funcional: usa el sprite actual con un tinte y un embiste rápido.
// Cuando tengas los sprites del cabezazo, solo hay que reemplazar la animación
// que se dispara acá adentro (buscá el comentario "SPRITES PENDIENTES").
// =============================================================================
function ejecutarCabezazo(escena) {
    cabezazoActivo = true;
    let dir = jugador.flipX ? -1 : 1;

    // --- SPRITES PENDIENTES: reemplazar este tinte/lunge por la animación real ---
    jugador.setTint(0x66ccff);
    jugador.setVelocityX(dir * 520);
    AudioSFX.play('cabezazo');

    escena.time.delayedCall(180, () => {
        if (!jugador || !jugador.active) return;

        const rango = 75;
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
            impactarJefe({ destroy: () => { }, danio: 4, y: jugador.y, active: true }, jefe);
        }

        actualizarHUD();
        if (jugador && jugador.active) jugador.clearTint();
        cabezazoActivo = false;
    });
}

// =============================================================================
// OLEADAS Y SPAWN (FIX #2, #8)
// =============================================================================
function verificarProgresionOleadas(escena) {
    if (!arbolSaqueado && jugador.x >= 480 && jugador.x <= 560) {
        arbolSaqueado = true;
        armaActual = 'NARANJA';
        municion = 999;
        AudioSFX.play('empanada');
        actualizarHUD();
        mostrarMensaje(escena, '¡HAS CHOREADO NARANJAS!\nPresiona Z o X para disparar');
    }

    // FIX #2: más enemigos por oleada / FIX #8: mezcla de izquierda y derecha
    const oleadas = [
        {
            id: 1, triggerX: 900, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', 0);
                spawnEnemigo(escena, 'HIPSTER', 0, 'derecha');
                spawnEnemigo(escena, 'HIPSTER', 350, 'derecha');
                spawnEnemigo(escena, 'HIPSTER', 750, 'izquierda');
            }
        },
        {
            id: 2, triggerX: 2200, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', 0);
                spawnEnemigo(escena, 'AGENTE', 0, 'derecha');
                spawnEnemigo(escena, 'HIPSTER', 400, 'izquierda');
                spawnEnemigo(escena, 'HIPSTER', 800, 'derecha');
            }
        },
        {
            id: 3, triggerX: 3500, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', 0);
                spawnEnemigo(escena, 'AGENTE', 0, 'derecha');
                spawnEnemigo(escena, 'AGENTE', 450, 'izquierda');
                spawnEnemigo(escena, 'GRANDOTE', 900, 'derecha');
            }
        },
        {
            id: 4, triggerX: 4700, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', 0);
                spawnEnemigo(escena, 'GRANDOTE', 0, 'izquierda');
                spawnEnemigo(escena, 'AGENTE', 450, 'derecha');
                spawnEnemigo(escena, 'HIPSTER', 850, 'derecha');
            }
        },
        {
            id: 5, triggerX: 5800, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', 0);
                spawnEnemigo(escena, 'GRANDOTE', 0, 'derecha');
                spawnEnemigo(escena, 'AGENTE', 450, 'izquierda');
                spawnEnemigo(escena, 'HIPSTER', 900, 'derecha');
                spawnEnemigo(escena, 'HIPSTER', 1300, 'izquierda');
            }
        },
        {
            id: 6, triggerX: 6800, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', 0);
                spawnEnemigo(escena, 'GRANDOTE', 0, 'derecha');
                spawnEnemigo(escena, 'GRANDOTE', 550, 'izquierda');
                spawnEnemigo(escena, 'AGENTE', 1000, 'derecha');
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

        // FIX #8: el enemigo puede entrar por la derecha (delante) o por la izquierda (detrás)
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
// (el flip horizontal ya funcionaba para ambas direcciones; ahora se aprovecha
// mejor porque los enemigos pueden aparecer de los dos lados - FIX #8)
// =============================================================================
function actualizarIAHipsters(escena) {
    const scrollX = escena.cameras.main.scrollX;
    hipsters.children.iterate((hipster) => {
        if (!hipster || !hipster.active) return;

        // Limpieza de enemigos rezagados
        if (hipster.x < scrollX - 300) {
            hipster.destroy();
            return;
        }

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

// FIX #7: ráfaga de 2 disparos más lentos y esquivables, con más pausa entre ráfagas
function actualizarIAAgentes(escena) {
    const scrollX = escena.cameras.main.scrollX;
    agentes.children.iterate((agente) => {
        if (!agente || !agente.active) return;

        if (agente.x < scrollX - 300) {
            agente.destroy();
            return;
        }

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
                    bala.setVelocity(dir * 190, 0); // FIX #7: antes 340, ahora más lenta y esquivable
                }
            };

            // Primer disparo de la ráfaga
            escena.time.delayedCall(250, dispararBala);
            // Segundo disparo, con pausa perceptible para poder esquivarlo
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

        if (grandote.x < scrollX - 300) {
            grandote.destroy();
            return;
        }

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
                if (grandote && grandote.active) {
                    grandote.atacandoCuerpoACuerpo = false;
                }
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
// JEFE FINAL (PALERMITANO MALVADO) - FIX #9: más resistente
// =============================================================================
function ejecutarRutinaJefe() {
    if (!jefe || !jefe.active || !jefeActivo || jefeAtacando || juegoTerminado) return;
    jefeAtacando = true;

    // Orientarse hacia el jugador
    let mirarIzquierda = (jugador.x < jefe.x);
    jefe.setFlipX(!mirarIzquierda);
    let dir = mirarIzquierda ? -1 : 1;

    let ataqueAleatorio = Math.random();

    if (ataqueAleatorio < 0.50) {
        jefe.anims.play('boss_cofee', true);
        jefe.setVelocityX(0);
        this.time.delayedCall(300, () => {
            if (jefe && jefe.active) {
                lanzarVasoCafe(this, jefe.x + (dir * 30), jefe.y - 10, dir * 360, 0);
            }
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

        // Retorno gradual hacia su área de combate (7650)
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

    if (vidaJefe <= 0) {
        derrotarJefe(jefeRef.scene);
    }
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
        targets: jefe,
        angle: 180,
        y: jefe.y - 80,
        alpha: 0,
        duration: 900,
        onComplete: () => {
            if (jefe) jefe.destroy();
            mostrarMensaje(escena, '¡HAS VENCIDO AL PALERMITANO!\nAvanza a la meta');
            // Si el jugador ya está cerca de la meta, activar victoria
            if (jugador && jugador.x >= 7750) {
                llegarALaMeta(jugador, metaFinal);
            }
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

    let txtReintentar = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 + 60, 'Presiona ESPACIO o haz clic para REINTENTAR', {
        fontSize: '16px', fontFamily: 'Arial Black', fill: '#00ffcc', stroke: '#000000', strokeThickness: 3, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    escena.tweens.add({
        targets: txtReintentar, alpha: 0.3, duration: 500, yoyo: true, repeat: -1
    });

    const reiniciarCallback = () => {
        escena.scene.restart();
    };

    escena.time.delayedCall(500, () => {
        escena.input.keyboard.once('keydown-SPACE', reiniciarCallback);
        escena.input.keyboard.once('keydown-Z', reiniciarCallback);
        escena.input.keyboard.once('keydown-X', reiniciarCallback);
        escena.input.keyboard.once('keydown-ENTER', reiniciarCallback);
        escena.input.once('pointerdown', reiniciarCallback);
    });
}

// =============================================================================
// RECOLECCIÓN
// =============================================================================
function recolectarEmpanada(jugadorRef, empanada) {
    if (!empanada || !empanada.active) return;
    if (Math.abs(carrilActual - empanada.y) > 25) return;
    empanada.destroy();
    puntos += 25;
    AudioSFX.play('empanada');

    // FIX #11: cada empanada suma progreso hacia el desbloqueo del cabezazo
    empanadasRecolectadas++;
    if (!cabezazoDesbloqueado && empanadasRecolectadas >= EMPANADAS_PARA_CABEZAZO) {
        cabezazoDesbloqueado = true;
        mostrarMensaje(jugadorRef.scene, '¡PODER DESBLOQUEADO!\nPresiona C para el CABEZAZO');
    }

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

// FIX #10: cartel de alerta antes de que arranque la insolación
function mostrarCartelAlerta(escena) {
    AudioSFX.play('alerta');

    const cartel = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 - 40, '⚠ ZONA DE MUCHO SOL ⚠\nBuscá achilatas para refrescarte', {
        fontSize: '20px', fontFamily: 'Arial Black', fill: '#ffcc00', stroke: '#000000', strokeThickness: 5, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(150).setAlpha(0).setScale(0.7);

    escena.tweens.add({
        targets: cartel,
        alpha: 1,
        scale: 1,
        duration: 250,
        ease: 'Back.easeOut',
        yoyo: false,
        onComplete: () => {
            escena.tweens.add({
                targets: cartel,
                alpha: 0,
                delay: 1800,
                duration: 500,
                onComplete: () => cartel.destroy()
            });
        }
    });
}

function actualizarSistemaInsolacion(escena, time) {
    if (jugador.x > 3200) {
        if (!insolacionActiva) {
            insolacionActiva = true;
            mostrarCartelAlerta(escena); // FIX #10: aparece primero el cartel de alerta
            escena.time.delayedCall(900, () => {
                if (solSprite) solSprite.setAlpha(1);
            });
            mostrarMensaje(escena, '¡EL SOL DE LA SIESTA APRIETA!\nBusca Achilatas para no insolarte');
        }

        // FIX #10: subida de insolación más lenta que antes (0.08 -> 0.035)
        nivelInsolacion = Math.min(100, nivelInsolacion + 0.035);
        dibujarBarraInsolacion();

        // FIX #10: el sol crece directamente proporcional al nivel de insolación
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

    const x = ANCHO_VISTA - 160;
    const y = 95;
    const ancho = 120;
    const alto = 12;

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
        targets: bannerNotificacion,
        scaleX: 1.15,
        scaleY: 1.15,
        duration: 180,
        yoyo: true,
        onComplete: () => {
            scene.tweens.add({
                targets: bannerNotificacion,
                alpha: 0,
                delay: 2600,
                duration: 600
            });
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
    escena.add.rectangle(ANCHO_VISTA / 2, ALTO_VISTA / 2, ANCHO_VISTA, ALTO_VISTA, 0x000000, 0.85)
        .setScrollFactor(0).setDepth(300);

    escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 - 60, '¡NIVEL 1 COMPLETADO!\n¡RECETA DE LA EMPANADA SALVADA!', {
        fontSize: '26px', fontFamily: 'Arial Black', fill: '#00ff66', stroke: '#000000', strokeThickness: 5, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 + 10, 'PUNTOS TOTALES: ' + puntos, {
        fontSize: '22px', fontFamily: 'Arial Black', fill: '#ffd700', stroke: '#000000', strokeThickness: 4, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    let txtReiniciar = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2 + 70, 'Presiona ESPACIO para VOLVER A JUGAR', {
        fontSize: '16px', fontFamily: 'Arial Black', fill: '#00ffcc', stroke: '#000000', strokeThickness: 3, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(301);

    escena.tweens.add({
        targets: txtReiniciar, alpha: 0.3, duration: 500, yoyo: true, repeat: -1
    });

    const reiniciarCallback = () => {
        escena.scene.restart();
    };

    escena.time.delayedCall(500, () => {
        escena.input.keyboard.once('keydown-SPACE', reiniciarCallback);
        escena.input.keyboard.once('keydown-Z', reiniciarCallback);
        escena.input.keyboard.once('keydown-X', reiniciarCallback);
        escena.input.keyboard.once('keydown-ENTER', reiniciarCallback);
        escena.input.once('pointerdown', reiniciarCallback);
    });
}