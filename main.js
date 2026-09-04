// =============================================================================
// HÉROE TUCUMANO 2D ARCADE - main.js
// Versión corregida: carriles fluidos, naranjas infinitas, cascotes,
// vehículos dinámicos saltables, vehículos estáticos de ambientación,
// cabezazo con sprites nuevos y fondo de fusión más grande.
// =============================================================================

const ANCHO_VISTA = 800;
const ALTO_VISTA = 450;
const ANCHO_MUNDO = 8000;

const CARRIL_SUPERIOR_Y = 370;
const CARRIL_INFERIOR_Y = 415;
const Y_ESCENARIO = 345;

const VELOCIDAD_JUGADOR = 230;
const VELOCIDAD_SANGUCHE = 330;
const SALTO_VELOCIDAD = -590;
const DURACION_CAMBIO_CARRIL = 300;
const RADIO_CARRIL = 28;

const AudioSFX = {
    ctx: null,
    init() {
        if (!this.ctx) {
            const AC = window.AudioContext || window.webkitAudioContext;
            if (AC) this.ctx = new AC();
        }
        if (this.ctx?.state === 'suspended') this.ctx.resume();
    },
    play(tipo) {
        if (!this.ctx) return;
        try {
            const now = this.ctx.currentTime;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.connect(gain);
            gain.connect(this.ctx.destination);
            const cfg = {
                salto: ['square', 160, 480, .12],
                disparo_naranja: ['triangle', 420, 140, .10],
                disparo_cascote: ['sawtooth', 240, 70, .14],
                empanada: ['sine', 523, 784, .20],
                achilata: ['sine', 600, 950, .18],
                sanguche: ['square', 300, 800, .38],
                golpe: ['sawtooth', 150, 40, .15],
                danio: ['sawtooth', 200, 70, .22],
                cabezazo: ['square', 500, 90, .20],
                alerta: ['square', 700, 500, .32],
                victoria: ['triangle', 261, 523, .55]
            }[tipo];
            if (!cfg) return;
            osc.type = cfg[0];
            osc.frequency.setValueAtTime(cfg[1], now);
            osc.frequency.exponentialRampToValueAtTime(Math.max(1, cfg[2]), now + cfg[3]);
            gain.gain.setValueAtTime(.16, now);
            gain.gain.exponentialRampToValueAtTime(.01, now + cfg[3]);
            osc.start(now);
            osc.stop(now + cfg[3]);
        } catch (_) {}
    }
};

const config = {
    type: Phaser.AUTO,
    width: ANCHO_VISTA,
    height: ALTO_VISTA,
    parent: 'contenedor-juego',
    pixelArt: true,
    scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
    physics: {
        default: 'arcade',
        arcade: { gravity: { y: 1300 }, debug: false }
    },
    scene: { preload, create, update }
};

let jugador, cursores, teclaZ, teclaX, teclaEnter, teclaC;
let fondoCerros, fondoUnificado, sueloRuta, sueloRuta2;
let proyectilesJugador, proyectilesEnemigos;
let hipsters, agentes, grandotes, colectivos, autosRuta;
let empanadas, potenciadores, achilatas, cascotesPilas, metaFinal;

let vidas = 3, salud = 3, puntos = 0;
const MAX_SALUD = 3;
let armaActual = 'NINGUNA';
let municion = 0;
let modoSanguchazo = false;

let textoVidas, barraVidaGrafico, textoPuntos, textoArma;
let textoEspecial, textoVidaJefe, bannerNotificacion;
let solSprite, barraCalorGrafico, textoCalor, capaTinteCalor;

let esInvulnerable = false;
let disparoPresionado = false;
let juegoTerminado = false;

let carrilActual = CARRIL_SUPERIOR_Y;
let carrilObjetivo = CARRIL_SUPERIOR_Y;
let cambiandoCarril = false;
let estaSaltando = false;
let tiempoInicioSalto = 0;
let vehiculoApoyado = null;

let arbolSaqueado = false;
let arbolNaranjasIntro;
let cascotesLevantados = false;
let empanadasRecolectadas = 0;
let cabezazoDesbloqueado = false;
let cabezazoActivo = false;
const EMPANADAS_PARA_CABEZAZO = 5;

let jefe, jefeActivo = false, vidaJefe = 110, jefeInvulnerable = false, jefeAtacando = false;

let enCinematica = true;
let pasoCinematica = 0;
let textoNarradoGlobal, cajaTextoGlobal, actoresCinematica = {};

let nivelInsolacion = 0;
let insolacionActiva = false;
let tiempoUltimoDanioSol = 0;
let oleadasActivadas = [];

new Phaser.Game(config);

function preload() {
    const img = (key, file) => this.load.image(key, 'assets/' + file);

    img('fondo_cerros', 'fondo_cerros.png');
    img('fusion_fondo', 'fusion_fondos.png');
    img('suelo_ruta', 'suelo_ruta.png');
    img('suelo_ruta2', 'suelo_ruta2.png');

    img('kiosco_coca', 'kiosco_coca.png');
    img('parada_colectivo', 'parada_colectivo.png');
    img('cartel_famailla', 'cartel_famailla.png');
    img('palmera', 'palmera.png');
    img('arbol_naranjas', 'arbol_naranjas.png');
    img('gruta_virgen', 'gruta_virgen.png');
    img('poste_luz', 'poste_luz.png');
    img('montaña_cascote', 'montaña_cascote.png');

    img('exprebus', 'exprebus.png');
    img('tesa', 'tesa.png');
    img('camion_limones', 'camion_limones.png');
    img('auto1', 'auto1.png');
    img('auto2', 'auto2.png');
    img('auto3', 'auto3.png');
    ['bus1','bus2','bus3','bus4'].forEach(k => img(k, k + '.png'));

    img('ciruja_comiendo', 'ciruja comiendo.png');
    img('campeona_empanadas', 'campeona empanadas.png');
    img('secuestro_campeona', 'secuestro_campeona.png');

    img('ciruja_idle', 'ciruja_idle.png');
    for (let i = 0; i <= 5; i++) img('ciruja_run' + i, 'ciruja_run' + i + '.png');
    img('ciruja_salto', 'ciruja_salto.png');
    for (let i = 1; i <= 4; i++) img('ciruja_salto' + i, 'ciruja_salto' + i + '.png');

    for (let i = 0; i <= 5; i++) img('ciruja_disparo_naranja' + i, 'ciruja_disparo_naranja' + i + '.png');
    for (let i = 0; i <= 4; i++) img('ciruja_disparo_cascote' + i, 'ciruja_disparo_cascote' + i + '.png');
    for (let i = 0; i <= 2; i++) img('ciruja_cabezazo' + i, 'ciruja_cabezazo' + i + '.png');

    for (let i = 1; i <= 5; i++) img('juntar_naranjas' + i, 'juntar_naranjas' + i + '.png');
    for (let i = 1; i <= 5; i++) img('juntar_cascote' + i, 'juntar_cascote' + i + '.png');

    img('naranja', 'naranja.png');
    img('cascote', 'cascote.png');
    img('empanada', 'empanada.png');
    img('sanguche', 'sanguche.png');
    img('achilata', 'achilata.png');
    img('sol', 'sol.png');
    img('botella_agua', 'botella_agua.png');
    img('bala', 'bala.png');
    img('cofee', 'cofee.png');

    img('hipster_agua1', 'hipster_agua1.png');
    img('hipster_agua2', 'hipster_agua2.png');
    for (let i = 1; i <= 3; i++) img('hipster_run' + i, 'hipster_run' + i + '.png');
    img('hipster_salto', 'hipster_salto.png');

    for (let i = 1; i <= 3; i++) img('agente_run' + i, 'agente_run' + i + '.png');
    img('agente_salto', 'agente_salto.png');
    img('agente_disparo_bala1', 'agente_disparo_bala1.png');
    img('agente_disparo_bala2', 'agente_disparo_bala2.png');

    for (let i = 1; i <= 3; i++) img('grandote_run' + i, 'grandote_run' + i + '.png');
    img('grandote_salto', 'grandote_salto.png');
    for (let i = 1; i <= 3; i++) img('grandote_punch' + i, 'grandote_punch' + i + '.png');

    img('final_boss_cofee1', 'final_boss_cofee1.png');
    img('final_boss_cofee2', 'final_boss_cofee2.png');
    img('final_boss_joke1', 'final_boss_joke1.png');
    img('final_boss_joke2', 'final_boss_joke2.png');
    img('final_boss_punch1', 'final_boss_punch1.png');
    img('final_boss_punch2', 'final_boss_punch2.png');
    img('final_boss_salto1', 'final_boss_salto1.png');
    img('final_boss_salto2', 'final_boss_salto2.png');
    img('final_boss_run1', 'final_boss_run1.png');
    img('final_boss_run2', 'final_boss_run2.png');
    img('final_boss_run3', 'final_boss_run3.png');
}

function create() {
    this.physics.world.setBounds(0, 0, ANCHO_MUNDO + 400, ALTO_VISTA);
    juegoTerminado = false;
    enCinematica = true;
    pasoCinematica = 0;
    vidas = 3; salud = MAX_SALUD; puntos = 0;
    armaActual = 'NINGUNA'; municion = 0; modoSanguchazo = false;
    esInvulnerable = false; disparoPresionado = false;
    carrilActual = CARRIL_SUPERIOR_Y;
    carrilObjetivo = CARRIL_SUPERIOR_Y;
    cambiandoCarril = false; estaSaltando = false; vehiculoApoyado = null;
    arbolSaqueado = false; cascotesLevantados = false;
    empanadasRecolectadas = 0; cabezazoDesbloqueado = false; cabezazoActivo = false;
    nivelInsolacion = 0; insolacionActiva = false; tiempoUltimoDanioSol = 0;
    jefeActivo = false; vidaJefe = 110; jefeInvulnerable = false; jefeAtacando = false;
    oleadasActivadas = [];

    fondoCerros = this.add.tileSprite(0, 0, ANCHO_VISTA, ALTO_VISTA, 'fondo_cerros')
        .setOrigin(0).setScrollFactor(0).setDepth(0);

    fondoUnificado = this.add.image(0, -95, 'fusion_fondo')
        .setOrigin(0, 0)
        .setDisplaySize(ANCHO_MUNDO + 500, ALTO_VISTA + 125)
        .setDepth(1);

    sueloRuta = this.add.tileSprite(0, Y_ESCENARIO - 20, ANCHO_VISTA, 160, 'suelo_ruta')
        .setOrigin(0).setScrollFactor(0).setDepth(3);
    sueloRuta2 = this.add.tileSprite(0, Y_ESCENARIO + 85, ANCHO_VISTA, 160, 'suelo_ruta2')
        .setOrigin(0).setScrollFactor(0).setDepth(3.1);

    crearEscenografia(this);
    crearAnimaciones(this);

    jugador = this.physics.add.sprite(80, carrilActual, 'ciruja_idle');
    jugador.setScale(.42);
    jugador.setCollideWorldBounds(true);
    jugador.body.allowGravity = false;
    jugador.setDragX(1800);
    configurarHitboxJugador();

    proyectilesJugador = this.physics.add.group({ allowGravity: false });
    proyectilesEnemigos = this.physics.add.group({ allowGravity: false });
    hipsters = this.physics.add.group({ allowGravity: false });
    agentes = this.physics.add.group({ allowGravity: false });
    grandotes = this.physics.add.group({ allowGravity: false });
    colectivos = this.physics.add.group({ allowGravity: false });
    autosRuta = this.physics.add.group({ allowGravity: false });
    empanadas = this.physics.add.group({ allowGravity: false });
    potenciadores = this.physics.add.group({ allowGravity: false });
    achilatas = this.physics.add.group({ allowGravity: false });
    cascotesPilas = this.physics.add.group({ allowGravity: false });

    crearVehiculosEstaticos(this);
    crearItems(this);

    this.physics.add.overlap(proyectilesJugador, colectivos, impactarVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, autosRuta, impactarVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, hipsters, impactarEnemigo, null, this);
    this.physics.add.overlap(proyectilesJugador, agentes, impactarEnemigo, null, this);
    this.physics.add.overlap(proyectilesJugador, grandotes, impactarEnemigo, null, this);
    this.physics.add.overlap(jugador, hipsters, interaccionJugadorEnemigo, null, this);
    this.physics.add.overlap(jugador, agentes, interaccionJugadorEnemigo, null, this);
    this.physics.add.overlap(jugador, grandotes, interaccionJugadorEnemigo, null, this);
    this.physics.add.overlap(jugador, proyectilesEnemigos, impactarJugadorConProyectilEnemigo, null, this);
    this.physics.add.overlap(jugador, empanadas, recolectarEmpanada, null, this);
    this.physics.add.overlap(jugador, achilatas, recolectarAchilata, null, this);
    this.physics.add.overlap(jugador, potenciadores, recolectarPotenciador, null, this);
    this.physics.add.overlap(jugador, cascotesPilas, recolectarCascotePila, null, this);

    jefe = this.physics.add.sprite(7650, CARRIL_INFERIOR_Y, 'final_boss_joke1');
    jefe.setOrigin(.5, 1).setScale(.78);
    jefe.body.allowGravity = false;
    jefe.anims.play('boss_joke', true);
    this.physics.add.overlap(proyectilesJugador, jefe, impactarJefe, null, this);
    this.physics.add.overlap(jugador, jefe, interaccionJugadorJefe, null, this);

    metaFinal = this.add.rectangle(7920, 400, 80, 180, 0, 0);
    this.physics.add.existing(metaFinal, true);
    this.physics.add.overlap(jugador, metaFinal, llegarALaMeta, null, this);

    crearHUD(this);

    cursores = this.input.keyboard.createCursorKeys();
    teclaZ = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.Z);
    teclaX = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.X);
    teclaEnter = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    teclaC = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.C);

    this.cameras.main.setBounds(0, 0, ANCHO_MUNDO + 400, ALTO_VISTA);
    this.cameras.main.startFollow(jugador, true, .08, .08);

    this.time.addEvent({ delay: 2200, callback: ejecutarRutinaJefe, callbackScope: this, loop: true });
    this.input.once('pointerdown', () => AudioSFX.init());
    this.input.keyboard.once('keydown', () => AudioSFX.init());
    iniciarCinematicaInteractiva(this);
}

function crearEscenografia(escena) {
    escena.add.image(130, Y_ESCENARIO, 'cartel_famailla').setOrigin(.5, 1).setScale(1.1).setDepth(2);
    escena.add.image(350, Y_ESCENARIO, 'gruta_virgen').setOrigin(.5, 1).setScale(.72).setDepth(2);

    arbolNaranjasIntro = escena.add.image(520, Y_ESCENARIO, 'arbol_naranjas')
        .setOrigin(.5, 1).setScale(.85).setDepth(2);

    escena.add.image(680, Y_ESCENARIO, 'palmera').setOrigin(.5, 1).setScale(.9).setDepth(2);
    escena.add.image(880, Y_ESCENARIO, 'kiosco_coca').setOrigin(.5, 1).setScale(1.05).setDepth(2);
    escena.add.image(1150, Y_ESCENARIO, 'palmera').setOrigin(.5, 1).setScale(.9).setDepth(2);

    [2100, 3600, 4800, 6100, 7100].forEach(x => {
        escena.add.image(x, Y_ESCENARIO, 'parada_colectivo').setOrigin(.5, 1).setScale(.85).setDepth(2);
        escena.add.image(x + 320, Y_ESCENARIO, 'arbol_naranjas').setOrigin(.5, 1).setScale(.85).setDepth(2);
    });

    [1000, 1350, 1850, 2500, 3200, 3950, 4500, 5200, 5800, 6450, 7400].forEach(x => {
        escena.add.image(x, Y_ESCENARIO, 'poste_luz').setOrigin(.5, 1).setScale(.85).setDepth(2);
    });
}

function crearAnimaciones(escena) {
    const anim = (key, frames, frameRate, repeat = 0) => {
        if (!escena.anims.exists(key)) escena.anims.create({ key, frames, frameRate, repeat });
    };

    anim('correr', Array.from({length:6}, (_,i)=>({key:'ciruja_run'+i})), 12, -1);
    anim('idle', [{key:'ciruja_idle'}], 1, -1);
    anim('salto', Array.from({length:4}, (_,i)=>({key:'ciruja_salto'+(i+1)})), 10, 0);
    anim('disparar_naranja', Array.from({length:6}, (_,i)=>({key:'ciruja_disparo_naranja'+i})), 14, 0);
    anim('disparar_cascote', Array.from({length:5}, (_,i)=>({key:'ciruja_disparo_cascote'+i})), 14, 0);
    anim('cabezazo', Array.from({length:3}, (_,i)=>({key:'ciruja_cabezazo'+i})), 12, 0);
    anim('juntar_naranjas', Array.from({length:5}, (_,i)=>({key:'juntar_naranjas'+(i+1)})), 10, 0);
    anim('juntar_cascote', Array.from({length:5}, (_,i)=>({key:'juntar_cascote'+(i+1)})), 10, 0);

    anim('hipster_run', [1,2,3].map(i=>({key:'hipster_run'+i})), 8, -1);
    anim('hipster_lanzar', [{key:'hipster_agua1'},{key:'hipster_agua2'}], 6, 0);
    anim('agente_run', [1,2,3].map(i=>({key:'agente_run'+i})), 7, -1);
    anim('agente_disparar', [{key:'agente_disparo_bala1'},{key:'agente_disparo_bala2'}], 7, 0);
    anim('grandote_run', [1,2,3].map(i=>({key:'grandote_run'+i})), 7, -1);
    anim('grandote_punch', [1,2,3].map(i=>({key:'grandote_punch'+i})), 9, 0);

    anim('boss_run', [1,2,3].map(i=>({key:'final_boss_run'+i})), 10, -1);
    anim('boss_salto', [{key:'final_boss_salto1'},{key:'final_boss_salto2'}], 6, 0);
    anim('boss_punch', [{key:'final_boss_punch1'},{key:'final_boss_punch2'}], 8, 0);
    anim('boss_joke', [{key:'final_boss_joke1'},{key:'final_boss_joke2'}], 4, -1);
    anim('boss_cofee', [{key:'final_boss_cofee1'},{key:'final_boss_cofee2'}], 9, 0);
}

function configurarHitboxJugador() {
    const ancho = jugador.width * .42;
    const alto = jugador.height * .78;
    jugador.body.setSize(ancho, alto);
    jugador.body.setOffset((jugador.width - ancho) / 2, jugador.height - alto);
}

function crearVehiculosEstaticos(escena) {
    crearAutoDecorativo(escena, 1900, CARRIL_SUPERIOR_Y, 'auto1', .95);
    crearAutoDecorativo(escena, 2600, CARRIL_SUPERIOR_Y, 'tesa', 1.25);
    crearAutoDecorativo(escena, 3300, CARRIL_SUPERIOR_Y, 'camion_limones', 1.35);
    crearAutoDecorativo(escena, 5000, CARRIL_SUPERIOR_Y, 'auto2', .95);
    crearAutoDecorativo(escena, 5900, CARRIL_SUPERIOR_Y, 'camion_limones', 1.35);
    crearAutoDecorativo(escena, 6700, CARRIL_SUPERIOR_Y, 'auto3', .95);
}

function crearAutoDecorativo(escena, x, y, key, scale) {
    return escena.add.image(x, y, key).setOrigin(.5, 1).setScale(scale).setDepth(y - 1);
}

function crearItems(escena) {
    [240, 750, 1350, 2000, 2700, 3400, 4100, 4900, 5600, 6300, 7000, 7500].forEach(x => {
        const y = Phaser.Math.RND.pick([CARRIL_SUPERIOR_Y, CARRIL_INFERIOR_Y]);
        const e = empanadas.create(x, y, 'empanada').setScale(.14);
        e.body.allowGravity = false;
    });

    [3200, 3600, 4300, 5400, 6500, 7200].forEach(x => {
        const y = Phaser.Math.RND.pick([CARRIL_SUPERIOR_Y, CARRIL_INFERIOR_Y]);
        const a = achilatas.create(x, y, 'achilata').setScale(.24);
        a.body.allowGravity = false;
    });

    [1450, 3000, 4400, 5700, 6900].forEach((x, i) => {
        crearPilaCascotes(escena, x, i % 2 ? CARRIL_INFERIOR_Y : CARRIL_SUPERIOR_Y);
    });

    crearSangucheMilanesa(escena, 2800, CARRIL_INFERIOR_Y);
    crearSangucheMilanesa(escena, 6200, CARRIL_INFERIOR_Y);
}

function crearPilaCascotes(escena, x, y) {
    const p = cascotesPilas.create(x, y, 'montaña_cascote').setScale(.62);
    p.body.allowGravity = false;
    p.tipo = 'CASCOTES';
    p.recogida = false;
    p.setDepth(y - 1);
    return p;
}

function crearSangucheMilanesa(escena, x, y) {
    const s = potenciadores.create(x, y, 'sanguche').setScale(.25);
    s.body.allowGravity = false;
    s.tipo = 'SANGUCHE';
    s.setDepth(y);
    escena.tweens.add({targets:s, y:y-5, duration:450, yoyo:true, repeat:-1, ease:'Sine.easeInOut'});
}

function update(time, delta) {
    if (!jugador?.active || juegoTerminado) return;

    fondoCerros.tilePositionX = this.cameras.main.scrollX * .05;
    sueloRuta.tilePositionX = this.cameras.main.scrollX;
    sueloRuta2.tilePositionX = this.cameras.main.scrollX;

    if (enCinematica) {
        if (Phaser.Input.Keyboard.JustDown(teclaZ) ||
            Phaser.Input.Keyboard.JustDown(teclaX) ||
            Phaser.Input.Keyboard.JustDown(cursores.space) ||
            Phaser.Input.Keyboard.JustDown(teclaEnter)) avanzarCinematica(this);
        return;
    }

    verificarProgresionOleadas(this);
    actualizarSistemaInsolacion(this, time);
    actualizarMovimientoJugador(this, time);
    actualizarColectivos(this);
    actualizarAutosRuta(this);
    actualizarIAHipsters(this);
    actualizarIAAgentes(this);
    actualizarIAGrandotes(this);
    actualizarCabezazo(this);
    comprobarChoquesVehiculos(this);

    if ((teclaZ.isDown || teclaX.isDown) && !disparoPresionado) {
        intentarDisparo(this);
        disparoPresionado = true;
    }
    if (teclaZ.isUp && teclaX.isUp) disparoPresionado = false;

    actualizarProfundidad();
    limpiarProyectiles(this);

    if (jefe?.active && !jefeActivo && jugador.x > 7300) {
        jefeActivo = true;
        actualizarBarraJefe();
        mostrarMensaje(this, '¡EL PALERMITANO MALVADO ESTÁ EN EL INGENIO!\n¡Derrótalo para salvar las empanadas!');
    }
}

function actualizarMovimientoJugador(escena, time) {
    const velocidad = modoSanguchazo ? VELOCIDAD_SANGUCHE : VELOCIDAD_JUGADOR;

    if (cursores.left.isDown) {
        jugador.setVelocityX(-velocidad);
        jugador.setFlipX(true);
        if (!estaSaltando && !cambiandoCarril && !cabezazoActivo) jugador.anims.play('correr', true);
    } else if (cursores.right.isDown) {
        jugador.setVelocityX(velocidad);
        jugador.setFlipX(false);
        if (!estaSaltando && !cambiandoCarril && !cabezazoActivo) jugador.anims.play('correr', true);
    } else {
        jugador.setVelocityX(0);
        if (!estaSaltando && !cambiandoCarril && !cabezazoActivo) jugador.anims.play('idle', true);
    }

    if (!estaSaltando && !cambiandoCarril) {
        if (Phaser.Input.Keyboard.JustDown(cursores.up) && carrilActual === CARRIL_INFERIOR_Y) {
            cambiarDeCarril(escena, CARRIL_SUPERIOR_Y);
        } else if (Phaser.Input.Keyboard.JustDown(cursores.down) && carrilActual === CARRIL_SUPERIOR_Y) {
            cambiarDeCarril(escena, CARRIL_INFERIOR_Y);
        }

        if (Phaser.Input.Keyboard.JustDown(cursores.space)) iniciarSalto(escena, time);
    } else if (estaSaltando) {
        if (jugador.body.velocity.y >= 0 && jugador.y >= carrilActual) aterrizarJugador();
        if (cursores.space.isUp && jugador.body.velocity.y < -140) jugador.setVelocityY(jugador.body.velocity.y * .55);
        if (time - tiempoInicioSalto > 1100) aterrizarJugador();
    }
}

function cambiarDeCarril(escena, nuevoCarril) {
    if (cambiandoCarril || estaSaltando || nuevoCarril === carrilActual) return;

    cambiandoCarril = true;
    carrilObjetivo = nuevoCarril;
    jugador.body.allowGravity = false;
    jugador.setVelocityY(0);
    jugador.anims.play('salto', true);
    AudioSFX.play('salto');

    escena.tweens.killTweensOf(jugador);
    escena.tweens.add({
        targets: jugador,
        y: nuevoCarril,
        duration: DURACION_CAMBIO_CARRIL,
        ease: 'Cubic.easeInOut',
        onUpdate: () => jugador.setDepth(jugador.y + jugador.displayHeight * .5),
        onComplete: () => {
            carrilActual = nuevoCarril;
            carrilObjetivo = nuevoCarril;
            cambiandoCarril = false;
            jugador.y = nuevoCarril;
            jugador.body.allowGravity = false;
            jugador.setVelocityY(0);
            if (!estaSaltando && !cabezazoActivo) jugador.anims.play('idle', true);
        }
    });
}

function iniciarSalto(escena, time) {
    if (cambiandoCarril || estaSaltando) return;
    estaSaltando = true;
    vehiculoApoyado = null;
    tiempoInicioSalto = time;
    jugador.body.allowGravity = true;
    jugador.setVelocityY(SALTO_VELOCIDAD);
    jugador.anims.play('salto', true);
    AudioSFX.play('salto');
}

function aterrizarJugador() {
    jugador.y = carrilActual;
    jugador.body.allowGravity = false;
    jugador.setVelocityY(0);
    estaSaltando = false;
    vehiculoApoyado = null;
    if (!disparandoActivo()) jugador.anims.play('idle', true);
}

function disparandoActivo() {
    return jugador.anims.currentAnim?.key === 'disparar_naranja' ||
           jugador.anims.currentAnim?.key === 'disparar_cascote' ||
           cabezazoActivo;
}

function crearBusDinamico(escena, x, key, velocidad) {
    const y = CARRIL_INFERIOR_Y;
    const b = colectivos.create(x, y, key).setOrigin(.5, 1).setScale(2.15);
    b.body.allowGravity = false;
    b.body.immovable = true;
    b.velocidadX = velocidad;
    b.vida = 8;
    b.averiado = false;
    b.tipoVehiculo = key;
    configurarHitboxVehiculo(b);
    return b;
}

function configurarHitboxVehiculo(v) {
    const w = v.width * .82;
    const h = v.height * .70;
    v.body.setSize(w, h);
    v.body.setOffset((v.width - w) / 2, v.height - h);
}

function actualizarColectivos(escena) {
    const scroll = escena.cameras.main.scrollX;
    colectivos.children.iterate(bus => {
        if (!bus?.active) return;
        bus.setVelocityX(bus.averiado ? 0 : bus.velocidadX);
        if (bus.x < scroll - 650 || bus.x > scroll + ANCHO_VISTA + 1400) bus.destroy();
        bus.setDepth(bus.y);
    });

    autosRuta.children.iterate(auto => {
        if (!auto?.active) return;
        auto.setVelocityX(auto.averiado ? 0 : auto.velocidadX);
        if (auto.x < scroll - 650 || auto.x > scroll + ANCHO_VISTA + 1400) auto.destroy();
        auto.setDepth(auto.y);
    });
}

function actualizarAutosRuta() {}

function comprobarChoquesVehiculos(escena) {
    if (estaSaltando || cambiandoCarril || vehiculoApoyado || esInvulnerable) return;

    const revisar = (vehiculo) => {
        if (!vehiculo?.active || vehiculo.averiado) return;
        if (Math.abs(vehiculo.y - carrilActual) > RADIO_CARRIL) return;
        const dx = Math.abs(jugador.x - vehiculo.x);
        const ancho = Math.max(35, vehiculo.displayWidth * .36);

        if (dx < ancho) {
            if (modoSanguchazo) {
                dañarVehiculoPorJugador(escena, vehiculo, 3);
            } else {
                recibirDanioJugador(escena);
                jugador.x += jugador.flipX ? 35 : -35;
            }
        }
    };

    colectivos.children.iterate(revisar);
    autosRuta.children.iterate(revisar);
}

function pararseSobreVehiculo() {}

function impactarVehiculo(proyectil, vehiculo) {
    if (!proyectil?.active || !vehiculo?.active || vehiculo.averiado) return;
    if (Math.abs(proyectil.y - vehiculo.y) > 65) return;
    const danio = proyectil.danio || 1;
    proyectil.destroy();
    dañarVehiculoPorJugador(vehiculo.scene, vehiculo, danio);
}

function dañarVehiculoPorJugador(escena, vehiculo, danio) {
    if (!vehiculo?.active || vehiculo.averiado) return;
    vehiculo.vida -= danio;
    vehiculo.setTint(0xff3333);
    AudioSFX.play('golpe');

    escena.time.delayedCall(100, () => {
        if (vehiculo?.active && !vehiculo.averiado) vehiculo.clearTint();
    });

    if (vehiculo.vida <= 0) {
        vehiculo.averiado = true;
        vehiculo.setVelocityX(0);
        vehiculo.setTint(0x666666);
        puntos += 250;
        actualizarHUD();
        mostrarTextoFlotante(escena, vehiculo.x, vehiculo.y - 100, '¡FRENADO!');
    }
}

function intentarDisparo(escena) {
    if (armaActual === 'NINGUNA') return;
    if (armaActual === 'CASCOTE' && municion <= 0) {
        armaActual = 'NARANJA';
        municion = 0;
    }

    const esCascote = armaActual === 'CASCOTE';
    const dir = jugador.flipX ? -1 : 1;
    const keyAnim = esCascote ? 'disparar_cascote' : 'disparar_naranja';
    const keyProjectile = esCascote ? 'cascote' : 'naranja';

    jugador.anims.play(keyAnim, true);
    AudioSFX.play(esCascote ? 'disparo_cascote' : 'disparo_naranja');

    const p = proyectilesJugador.create(jugador.x + dir * 15, jugador.y - 12, keyProjectile);
    p.setScale(esCascote ? .14 : .095);
    p.body.allowGravity = false;
    p.setVelocityX(dir * (esCascote ? 700 : 560));
    p.setVelocityY(esCascote ? -15 : 0);
    p.velocidadGiro = dir * (esCascote ? 22 : 18);
    p.danio = esCascote ? 3 : 1;
    p.setDepth(jugador.y + jugador.displayHeight * .5 + 3);

    if (esCascote) {
        municion--;
        if (municion <= 0) {
            municion = 0;
            armaActual = 'NARANJA';
            mostrarMensaje(escena, '¡SIN CASCOTES!\nVolvés a las naranjas infinitas');
        }
    }
    actualizarHUD();
}

function actualizarProfundidad() {
    const profundidad = obj => obj.setDepth(obj.y + (obj.displayHeight || 0) * .5);
    if (jugador?.active) profundidad(jugador);
    [hipsters, agentes, grandotes, empanadas, achilatas, cascotesPilas].forEach(grupo => {
        grupo?.children.iterate(e => { if (e?.active) profundidad(e); });
    });
    colectivos?.children.iterate(e => { if (e?.active) e.setDepth(e.y); });
}

function limpiarProyectiles(escena) {
    const left = escena.cameras.main.scrollX - 250;
    const right = escena.cameras.main.scrollX + ANCHO_VISTA + 250;
    [proyectilesJugador, proyectilesEnemigos].forEach(grupo => {
        grupo.children.iterate(p => {
            if (!p?.active) return;
            p.angle += p.velocidadGiro || 0;
            if (p.x < left || p.x > right || p.y < -100 || p.y > ALTO_VISTA + 150) p.destroy();
        });
    });
}

function verificarProgresionOleadas(escena) {
    if (!arbolSaqueado && jugador.x >= 455 && jugador.x <= 600 && !cambiandoCarril && !estaSaltando) {
        arbolSaqueado = true;
        armaActual = 'NARANJA';
        municion = 0;
        jugador.anims.play('juntar_naranjas', true);
        AudioSFX.play('empanada');
        mostrarMensaje(escena, '¡CHOREASTE LAS NARANJAS!\nAhora tenés NARANJAS INFINITAS');
        actualizarHUD();
        escena.time.delayedCall(550, () => {
            if (jugador?.active && !juegoTerminado) jugador.anims.play('idle', true);
        });
        if (arbolNaranjasIntro?.active) escena.tweens.add({targets:arbolNaranjasIntro,alpha:.35,duration:300});
    }

    const oleadas = [
        [900, [['HIPSTER','derecha',0],['HIPSTER','derecha',350],['HIPSTER','izquierda',750]], 'exprebus'],
        [2200, [['AGENTE','derecha',0],['HIPSTER','izquierda',400],['HIPSTER','derecha',800]], 'tesa'],
        [3500, [['AGENTE','derecha',0],['AGENTE','izquierda',450],['GRANDOTE','derecha',900]], 'exprebus'],
        [4700, [['GRANDOTE','izquierda',0],['AGENTE','derecha',450],['HIPSTER','derecha',850]], 'tesa'],
        [5800, [['GRANDOTE','derecha',0],['AGENTE','izquierda',450],['HIPSTER','derecha',900],['HIPSTER','izquierda',1300]], 'exprebus'],
        [6800, [['GRANDOTE','derecha',0],['GRANDOTE','izquierda',550],['AGENTE','derecha',1000]], 'tesa']
    ];

    oleadas.forEach(([trigger, enemies, vehicle]) => {
        if (jugador.x >= trigger && !oleadasActivadas.includes(trigger)) {
            oleadasActivadas.push(trigger);
            lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 100, vehicle, vehicle === 'tesa' ? 410 : 450);
            enemies.forEach(([tipo,lado,retraso]) => spawnEnemigo(escena,tipo,retraso,lado));
        }
    });

    if (jugador.x > 1500 && !oleadasActivadas.includes('limon1')) {
        oleadasActivadas.push('limon1');
        lanzarColectivo(escena, jugador.x + 1150, 'camion_limones', 500);
    }
    if (jugador.x > 4300 && !oleadasActivadas.includes('limon2')) {
        oleadasActivadas.push('limon2');
        lanzarColectivo(escena, jugador.x + 1150, 'camion_limones', 520);
    }
}

function lanzarColectivo(escena, x, spriteKey, velocidad) {
    const key = spriteKey === 'exprebus' ? Phaser.Math.RND.pick(['bus1','bus2','bus3','bus4']) : spriteKey;
    const bus = crearBusDinamico(escena, x, key, velocidad);
    bus.spriteBase = spriteKey;
    bus.vida = spriteKey === 'camion_limones' ? 10 : 8;
    return bus;
}

function spawnEnemigo(escena, tipo, retrasoMs, lado) {
    escena.time.delayedCall(retrasoMs, () => {
        if (juegoTerminado) return;
        const dirEntrada = lado === 'izquierda' ? -1 : 1;
        const x = dirEntrada > 0 ? escena.cameras.main.scrollX + ANCHO_VISTA + 70 : Math.max(40, escena.cameras.main.scrollX - 70);
        const y = Phaser.Math.RND.pick([CARRIL_SUPERIOR_Y, CARRIL_INFERIOR_Y]);

        if (tipo === 'HIPSTER') {
            const e = hipsters.create(x,y,'hipster_agua1').setScale(.40);
            e.vida=3; e.puntosValor=75; e.estaDisparando=false;
            e.ultimoAtaque=escena.time.now+Phaser.Math.Between(900,1600);
            e.body.allowGravity=false;
        } else if (tipo === 'AGENTE') {
            const e = agentes.create(x,y,'agente_run1').setScale(.40);
            e.vida=5; e.puntosValor=150; e.estaDisparando=false;
            e.ultimoDisparo=escena.time.now+Phaser.Math.Between(800,1500);
            e.body.allowGravity=false;
        } else {
            const e = grandotes.create(x,y,'grandote_run1').setScale(.72);
            e.vida=10; e.puntosValor=300; e.atacandoCuerpoACuerpo=false;
            e.body.allowGravity=false;
        }
    });
}

function actualizarIAHipsters(escena) {
    hipsters.children.iterate(h => {
        if (!h?.active) return;
        if (h.x < escena.cameras.main.scrollX - 350 || h.x > ANCHO_MUNDO + 500) { h.destroy(); return; }
        const dir = jugador.x < h.x ? -1 : 1;
        h.setFlipX(dir > 0);
        const dist = Math.abs(h.x - jugador.x);
        if (!h.estaDisparando && dist < 650 && escena.time.now > h.ultimoAtaque && Math.abs(h.y-carrilActual)<35) {
            h.estaDisparando=true; h.setVelocityX(0); h.anims.play('hipster_lanzar',true);
            escena.time.delayedCall(280,()=>{
                if(!h?.active)return;
                const b=proyectilesEnemigos.create(h.x+dir*18,h.y-8,'botella_agua').setScale(.14);
                b.setVelocityX(dir*270); b.body.allowGravity=false;
            });
            escena.time.delayedCall(900,()=>{if(h?.active){h.ultimoAtaque=escena.time.now+1500;h.estaDisparando=false;}});
            return;
        }
        if(!h.estaDisparando){h.setVelocityX(dir*65);h.anims.play('hipster_run',true);}
    });
}

function actualizarIAAgentes(escena) {
    agentes.children.iterate(a => {
        if (!a?.active) return;
        if (a.x < escena.cameras.main.scrollX - 350 || a.x > ANCHO_MUNDO + 500) { a.destroy(); return; }
        const dir=jugador.x<a.x?-1:1;
        a.setFlipX(dir>0);
        const dist=Math.abs(a.x-jugador.x);
        if(!a.estaDisparando&&dist<700&&escena.time.now>a.ultimoDisparo&&Math.abs(a.y-carrilActual)<40){
            a.estaDisparando=true;a.setVelocityX(0);a.anims.play('agente_disparar',true);
            [250,650].forEach(delay=>escena.time.delayedCall(delay,()=>{
                if(!a?.active)return;
                const b=proyectilesEnemigos.create(a.x+dir*20,a.y-8,'bala').setScale(.20);
                b.setVelocityX(dir*190);b.body.allowGravity=false;
            }));
            escena.time.delayedCall(1100,()=>{if(a?.active){a.ultimoDisparo=escena.time.now+1600;a.estaDisparando=false;}});
            return;
        }
        if(!a.estaDisparando){a.setVelocityX(Math.abs(dist)>180?dir*75:0);a.anims.play('agente_run',true);}
    });
}

function actualizarIAGrandotes(escena) {
    grandotes.children.iterate(g => {
        if (!g?.active) return;
        if (g.x < escena.cameras.main.scrollX - 350 || g.x > ANCHO_MUNDO + 500) { g.destroy(); return; }
        const dir=jugador.x<g.x?-1:1;
        g.setFlipX(dir>0);
        const dist=Math.abs(g.x-jugador.x);
        if(!g.atacandoCuerpoACuerpo&&dist<95&&Math.abs(g.y-carrilActual)<35&&!estaSaltando&&!cambiandoCarril){
            g.atacandoCuerpoACuerpo=true;g.setVelocityX(0);g.anims.play('grandote_punch',true);
            escena.time.delayedCall(300,()=>{if(g?.active&&Math.abs(g.x-jugador.x)<105&&Math.abs(g.y-carrilActual)<35)recibirDanioJugador(escena);});
            escena.time.delayedCall(700,()=>{if(g?.active)g.atacandoCuerpoACuerpo=false;});
            return;
        }
        if(!g.atacandoCuerpoACuerpo){g.setVelocityX(dir*100);g.anims.play('grandote_run',true);}
    });
}

function impactarEnemigo(proyectil, enemigo) {
    if(!proyectil?.active||!enemigo?.active)return;
    if(Math.abs(proyectil.y-enemigo.y)>55)return;
    const d=proyectil.danio||1;proyectil.destroy();
    if(enemigo.invulnerable)return;
    enemigo.invulnerable=true;enemigo.vida-=d;enemigo.setTint(0xff3333);AudioSFX.play('golpe');
    enemigo.scene.time.delayedCall(150,()=>{if(enemigo?.active){enemigo.clearTint();enemigo.invulnerable=false;}});
    if(enemigo.vida<=0){puntos+=enemigo.puntosValor||50;enemigo.destroy();actualizarHUD();}
}

function actualizarCabezazo(escena) {
    if (!cabezazoDesbloqueado || cabezazoActivo) return;
    if (Phaser.Input.Keyboard.JustDown(teclaC) && !estaSaltando && !cambiandoCarril) ejecutarCabezazo(escena);
}

function ejecutarCabezazo(escena) {
    cabezazoActivo=true;
    const dir=jugador.flipX?-1:1;
    jugador.setVelocityX(dir*520);
    jugador.anims.play('cabezazo',true);
    AudioSFX.play('cabezazo');

    escena.time.delayedCall(120,()=>{
        if(!jugador?.active)return;
        const golpearGrupo=(grupo,valor)=>{
            grupo.children.iterate(e=>{
                if(e?.active&&Math.abs(e.x-jugador.x)<85&&Math.abs(e.y-carrilActual)<35){e.destroy();puntos+=valor;}
            });
        };
        golpearGrupo(hipsters,75);golpearGrupo(agentes,150);golpearGrupo(grandotes,300);
        colectivos.children.iterate(v=>{
            if(v?.active&&!v.averiado&&Math.abs(v.x-jugador.x)<95&&Math.abs(v.y-carrilActual)<35)dañarVehiculoPorJugador(escena,v,4);
        });
        if(jefe?.active&&jefeActivo&&!jefeInvulnerable&&Math.abs(jefe.x-jugador.x)<90&&Math.abs(jefe.y-carrilActual)<35)
            impactarJefe({active:true,danio:4,destroy(){},y:jugador.y},jefe);
        actualizarHUD();
    });

    escena.time.delayedCall(300,()=>{
        cabezazoActivo=false;
        if(jugador?.active){jugador.setVelocityX(0);jugador.anims.play('idle',true);}
    });
}

function ejecutarRutinaJefe() {
    if(!jefe?.active||!jefeActivo||jefeAtacando||juegoTerminado)return;
    jefeAtacando=true;
    const dir=jugador.x<jefe.x?-1:1;
    jefe.setFlipX(dir<0);
    if(Math.random()<.55){
        jefe.setVelocityX(0);jefe.anims.play('boss_cofee',true);
        this.time.delayedCall(300,()=>{if(jefe?.active)lanzarVasoCafe(this,jefe.x+dir*30,jefe.y-20,dir*360);});
        this.time.delayedCall(900,()=>{if(jefe?.active){jefe.anims.play('boss_joke',true);jefeAtacando=false;}});
    }else{
        jefe.anims.play('boss_run',true);jefe.setVelocityX(dir*210);
        this.time.delayedCall(450,()=>{if(jefe?.active)lanzarVasoCafe(this,jefe.x+dir*30,jefe.y-20,dir*420);});
        this.time.delayedCall(1200,()=>{if(jefe?.active){jefe.setVelocityX(0);jefe.anims.play('boss_joke',true);jefeAtacando=false;}});
    }
}

function lanzarVasoCafe(escena,x,y,vx) {
    const c=proyectilesEnemigos.create(x,y,'cofee').setScale(.25);
    c.body.allowGravity=false;c.setVelocity(vx,0);c.velocidadGiro=-16;
}

function impactarJefe(proyectil,jefeRef) {
    if(!proyectil?.active||!jefeRef?.active)return;
    if(Math.abs(proyectil.y-jefeRef.y)>65)return;
    const d=proyectil.danio||1;proyectil.destroy();AudioSFX.play('golpe');
    if(jefeInvulnerable||!jefeActivo)return;
    vidaJefe-=d;puntos+=60*d;actualizarHUD();actualizarBarraJefe();
    jefeInvulnerable=true;jefeRef.setTint(0xff3333);
    jefeRef.scene.time.delayedCall(170,()=>{if(jefeRef?.active){jefeRef.clearTint();jefeInvulnerable=false;}});
    if(vidaJefe<=0)derrotarJefe(jefeRef.scene);
}

function actualizarBarraJefe() {
    if(textoVidaJefe)textoVidaJefe.setText('PALERMITANO: '+'█'.repeat(Math.max(0,Math.ceil(vidaJefe/5))));
}

function derrotarJefe(escena) {
    puntos+=1500;actualizarHUD();AudioSFX.play('victoria');textoVidaJefe.setText('¡RECETA SALVADA!');
    escena.tweens.add({targets:jefe,angle:180,y:jefe.y-80,alpha:0,duration:900,onComplete:()=>{
        if(jefe)jefe.destroy();mostrarMensaje(escena,'¡HAS VENCIDO AL PALERMITANO!\n¡LLEGÁ A LA META!');
    }});
}

function interaccionJugadorEnemigo(j,e) {
    if(!e?.active||estaSaltando||cambiandoCarril)return;
    if(Math.abs(e.y-carrilActual)>RADIO_CARRIL)return;
    if(modoSanguchazo){e.destroy();puntos+=100;AudioSFX.play('golpe');actualizarHUD();}
    else recibirDanioJugador(j.scene);
}

function interaccionJugadorJefe(j,jr) {
    if(!jr?.active||!jefeActivo||estaSaltando||cambiandoCarril)return;
    if(Math.abs(jr.y-carrilActual)>RADIO_CARRIL)return;
    if(modoSanguchazo)impactarJefe({active:true,danio:3,destroy(){},y:j.y},jr);
    else recibirDanioJugador(j.scene);
}

function impactarJugadorConProyectilEnemigo(j,p) {
    if(!p?.active||estaSaltando||cambiandoCarril)return;
    if(Math.abs(p.y-carrilActual)>RADIO_CARRIL)return;
    p.destroy();recibirDanioJugador(j.scene);
}

function recibirDanioJugador(escena) {
    if(esInvulnerable||juegoTerminado)return;
    salud--;AudioSFX.play('danio');actualizarHUD();
    if(salud<=0){vidas--;salud=MAX_SALUD;actualizarHUD();}
    if(vidas<=0){mostrarGameOver(escena);return;}
    esInvulnerable=true;jugador.setVelocityX(jugador.flipX?170:-170);
    let n=0;
    escena.time.addEvent({delay:100,repeat:7,callback:()=>{
        if(!jugador?.active)return;
        jugador.alpha=jugador.alpha===1?.3:1;n++;
        if(n>=8){jugador.alpha=1;esInvulnerable=false;}
    }});
}

function recolectarEmpanada(j,e) {
    if(!e?.active||Math.abs(e.y-carrilActual)>RADIO_CARRIL)return;
    e.destroy();puntos+=25;empanadasRecolectadas++;AudioSFX.play('empanada');
    if(!cabezazoDesbloqueado&&empanadasRecolectadas>=EMPANADAS_PARA_CABEZAZO){
        cabezazoDesbloqueado=true;mostrarMensaje(j.scene,'¡CABEZAZO DESBLOQUEADO!\nPresioná C para usarlo');
    }
    actualizarHUD();
}

function recolectarAchilata(j,a) {
    if(!a?.active||Math.abs(a.y-carrilActual)>RADIO_CARRIL)return;
    a.destroy();nivelInsolacion=Math.max(0,nivelInsolacion-50);puntos+=100;AudioSFX.play('achilata');
    dibujarBarraInsolacion();actualizarHUD();mostrarMensaje(j.scene,'¡ACHILATA!\nInsolación reducida');
}

function recolectarPotenciador(j,item) {
    if(!item?.active||Math.abs(item.y-carrilActual)>RADIO_CARRIL)return;
    if(item.tipo==='SANGUCHE'){
        item.destroy();salud=MAX_SALUD;vidas=Math.min(3,vidas+1);
        activarModoSanguchazo(j.scene);AudioSFX.play('sanguche');
        mostrarMensaje(j.scene,'¡SÁNGUCHE DE MILANGA!\nSalud completa + FURIA');
    }
    actualizarHUD();
}

function recolectarCascotePila(j,pila) {
    if(!pila?.active||pila.recogida||Math.abs(pila.y-carrilActual)>RADIO_CARRIL)return;
    pila.recogida=true;cascotesLevantados=true;armaActual='CASCOTE';municion+=20;
    j.anims.play('juntar_cascote',true);AudioSFX.play('golpe');pila.destroy();
    mostrarMensaje(j.scene,'¡CASCOTES!\n+20 proyectiles pesados');actualizarHUD();
    j.scene.time.delayedCall(550,()=>{if(j?.active&&!cabezazoActivo)j.anims.play('idle',true);});
}

function activarModoSanguchazo(escena) {
    modoSanguchazo=true;textoEspecial.setText('¡FURIA DE MILANGA!');jugador.setTint(0xffd700);
    escena.time.delayedCall(8000,()=>{modoSanguchazo=false;textoEspecial.setText('');if(jugador?.active&&!esInvulnerable)jugador.clearTint();});
}

function actualizarSistemaInsolacion(escena,time) {
    if(jugador.x<=3200)return;
    if(!insolacionActiva){
        insolacionActiva=true;mostrarCartelAlerta(escena);
        escena.time.delayedCall(800,()=>{if(solSprite)solSprite.setAlpha(1);});
    }
    nivelInsolacion=Math.min(100,nivelInsolacion+.035);
    const p=nivelInsolacion/100;
    solSprite.setScale(.4+p*.7);capaTinteCalor.setAlpha(p*.22);dibujarBarraInsolacion();
    if(nivelInsolacion>=100&&time>tiempoUltimoDanioSol+2000){tiempoUltimoDanioSol=time;mostrarMensaje(escena,'¡ESTÁS INSOLADO!');recibirDanioJugador(escena);}
}

function mostrarCartelAlerta(escena) {
    AudioSFX.play('alerta');
    const t=escena.add.text(ANCHO_VISTA/2,ALTO_VISTA/2-40,'⚠ ZONA DE MUCHO SOL ⚠\nBuscá achilatas para refrescarte',{fontSize:'20px',fontFamily:'Arial Black',fill:'#ffcc00',stroke:'#000',strokeThickness:5,align:'center'}).setOrigin(.5).setScrollFactor(0).setDepth(150).setAlpha(0);
    escena.tweens.add({targets:t,alpha:1,duration:250,onComplete:()=>escena.tweens.add({targets:t,alpha:0,delay:1700,duration:500,onComplete:()=>t.destroy()})});
}

function dibujarBarraInsolacion() {
    if(!barraCalorGrafico)return;
    barraCalorGrafico.clear();if(!insolacionActiva)return;
    const x=ANCHO_VISTA-160,y=95,w=120,h=12;
    barraCalorGrafico.lineStyle(2,0x000,1);barraCalorGrafico.strokeRect(x,y,w,h);
    const color=nivelInsolacion>75?0xff0000:nivelInsolacion>45?0xffaa00:0xffff00;
    barraCalorGrafico.fillStyle(color,1);barraCalorGrafico.fillRect(x,y,w*nivelInsolacion/100,h);
    textoCalor.setText('INSOLACIÓN: '+Math.floor(nivelInsolacion)+'%');
}

function crearHUD(escena) {
    textoVidas=escena.add.text(20,15,'VIDAS: '+vidas,{fontSize:'18px',fontFamily:'Arial Black',fill:'#fff',stroke:'#000',strokeThickness:4}).setScrollFactor(0).setDepth(100);
    barraVidaGrafico=escena.add.graphics().setScrollFactor(0).setDepth(100);
    textoPuntos=escena.add.text(20,62,'PUNTOS: '+puntos,{fontSize:'18px',fontFamily:'Arial Black',fill:'#ffd700',stroke:'#000',strokeThickness:4}).setScrollFactor(0).setDepth(100);
    textoArma=escena.add.text(20,88,'ARMA: DESARMADO',{fontSize:'16px',fontFamily:'Arial Black',fill:'#ff8800',stroke:'#000',strokeThickness:4}).setScrollFactor(0).setDepth(100);
    textoEspecial=escena.add.text(ANCHO_VISTA/2,28,'',{fontSize:'18px',fontFamily:'Arial Black',fill:'#00ffcc',stroke:'#000',strokeThickness:5}).setOrigin(.5).setScrollFactor(0).setDepth(100);
    textoVidaJefe=escena.add.text(ANCHO_VISTA-340,20,'',{fontSize:'16px',fontFamily:'Arial Black',fill:'#ff3333',stroke:'#000',strokeThickness:4}).setScrollFactor(0).setDepth(100);
    bannerNotificacion=escena.add.text(ANCHO_VISTA/2,110,'',{fontSize:'18px',fontFamily:'Arial Black',fill:'#ffff00',stroke:'#000',strokeThickness:5,align:'center'}).setOrigin(.5).setScrollFactor(0).setDepth(100).setAlpha(0);
    capaTinteCalor=escena.add.rectangle(ANCHO_VISTA/2,ALTO_VISTA/2,ANCHO_VISTA,ALTO_VISTA,0xff5500,0).setScrollFactor(0).setDepth(90);
    solSprite=escena.add.image(ANCHO_VISTA-70,70,'sol').setScrollFactor(0).setScale(.4).setAlpha(0).setDepth(110);
    barraCalorGrafico=escena.add.graphics().setScrollFactor(0).setDepth(110);
    textoCalor=escena.add.text(ANCHO_VISTA-160,115,'',{fontSize:'13px',fontFamily:'Arial Black',fill:'#ffaa00',stroke:'#000',strokeThickness:3}).setScrollFactor(0).setDepth(110);
    dibujarBarraSalud();
}

function dibujarBarraSalud() {
    if(!barraVidaGrafico)return;
    barraVidaGrafico.clear();
    const x=20,y=40,w=28,h=12,g=6;
    for(let i=0;i<MAX_SALUD;i++){
        barraVidaGrafico.lineStyle(2,0x000,1);barraVidaGrafico.strokeRect(x+i*(w+g),y,w,h);
        barraVidaGrafico.fillStyle(i<salud?(salud===3?0x00ff00:salud===2?0xffcc00:0xff2222):0x333333,i<salud?1:.6);
        barraVidaGrafico.fillRect(x+i*(w+g),y,w,h);
    }
}

function actualizarHUD() {
    if(!textoVidas)return;
    textoVidas.setText('VIDAS: '+vidas);textoPuntos.setText('PUNTOS: '+puntos);dibujarBarraSalud();
    textoArma.setText(armaActual==='NARANJA'?'ARMA: NARANJA (∞)':armaActual==='CASCOTE'?'ARMA: CASCOTE ('+municion+')':'ARMA: DESARMADO');
}

function mostrarMensaje(escena,texto) {
    if(!bannerNotificacion)return;
    escena.tweens.killTweensOf(bannerNotificacion);
    bannerNotificacion.setText(texto).setAlpha(1).setScale(1);
    escena.tweens.add({targets:bannerNotificacion,scaleX:1.08,scaleY:1.08,duration:160,yoyo:true,onComplete:()=>{
        escena.tweens.add({targets:bannerNotificacion,alpha:0,delay:2600,duration:500});
    }});
}

function mostrarTextoFlotante(escena,x,y,texto) {
    const t=escena.add.text(x,y,texto,{fontSize:'14px',fontFamily:'Arial Black',fill:'#ffaa00',stroke:'#000',strokeThickness:3}).setOrigin(.5).setDepth(150);
    escena.tweens.add({targets:t,y:y-30,alpha:0,duration:800,onComplete:()=>t.destroy()});
}

function iniciarCinematicaInteractiva(escena) {
    jugador.setVisible(false);escena.cameras.main.stopFollow();
    actoresCinematica.mesa=escena.add.image(190,CARRIL_SUPERIOR_Y,'ciruja_comiendo').setScale(.85).setDepth(50);
    actoresCinematica.campeona=escena.add.image(290,CARRIL_SUPERIOR_Y-5,'campeona_empanadas').setScale(.8).setDepth(50);
    cajaTextoGlobal=escena.add.rectangle(ANCHO_VISTA/2,ALTO_VISTA-60,ANCHO_VISTA-60,75,0x000,.9).setScrollFactor(0).setDepth(200);
    textoNarradoGlobal=escena.add.text(ANCHO_VISTA/2,ALTO_VISTA-60,'FAMAILLÁ, CAPITAL DE LA EMPANADA.\nEL CIRUJA DISFRUTA DE UN MEDIODÍA DE PAZ...\n(Presioná Z, Espacio o Enter)',{fontSize:'14px',fontFamily:'Arial Black',fill:'#00ffcc',align:'center'}).setOrigin(.5).setScrollFactor(0).setDepth(201);
    escena.cameras.main.pan(400,ALTO_VISTA/2,1400,'Sine.easeInOut');
    escena.input.once('pointerdown',()=>{if(enCinematica)avanzarCinematica(escena);});
}

function avanzarCinematica(escena) {
    pasoCinematica++;
    if(pasoCinematica===1){
        textoNarradoGlobal.setText('¡ATAQUE SORPRESA!\nLOS AGENTES ATRAPAN A LA CAMPEONA...\n(Presioná Z para continuar)').setFill('#ff3333');
        if(actoresCinematica.campeona)actoresCinematica.campeona.destroy();
        actoresCinematica.raptores=escena.add.image(290,CARRIL_SUPERIOR_Y-5,'secuestro_campeona').setScale(.85).setDepth(55);
        actoresCinematica.jefeIntro=escena.add.sprite(200,CARRIL_SUPERIOR_Y-10,'final_boss_joke1').setScale(.75).setDepth(56);
        actoresCinematica.jefeIntro.anims.play('boss_joke',true);AudioSFX.play('danio');
    }else if(pasoCinematica===2){
        textoNarradoGlobal.setText('PALERMITANO MALVADO: "¡LLEVENLA AL INGENIO!\n¡VAMOS A SERVIR LA EMPANADA DECONSTRUIDA EN FRASCO!"\n(Presioná Z para salir a perseguirlos)').setFill('#ffff00');
        escena.tweens.add({targets:actoresCinematica.raptores,x:1100,duration:2200});
        escena.tweens.add({targets:actoresCinematica.jefeIntro,x:1150,duration:2000,onComplete:()=>{actoresCinematica.raptores?.destroy();actoresCinematica.jefeIntro?.destroy();}});
    }else{
        cajaTextoGlobal?.destroy();textoNarradoGlobal?.destroy();actoresCinematica.mesa?.destroy();
        actoresCinematica.jefeIntro?.destroy();actoresCinematica.raptores?.destroy();
        jugador.setPosition(80,CARRIL_SUPERIOR_Y);jugador.setVisible(true);
        carrilActual=CARRIL_SUPERIOR_Y;carrilObjetivo=carrilActual;estaSaltando=false;cambiandoCarril=false;
        enCinematica=false;escena.cameras.main.startFollow(jugador,true,.08,.08);
        mostrarMensaje(escena,'¡SALVÁ LA RECETA TRADICIONAL!\nAVANZÁ POR LA RUTA 38');
    }
}

function mostrarGameOver(escena) {
    juegoTerminado=true;jugador.setVelocity(0);jugador.setTint(0xff2222);
    escena.add.rectangle(ANCHO_VISTA/2,ALTO_VISTA/2,ANCHO_VISTA,ALTO_VISTA,0x000,.85).setScrollFactor(0).setDepth(300);
    escena.add.text(ANCHO_VISTA/2,ALTO_VISTA/2-50,'¡TE LIQUIDARON EN LA RUTA!',{fontSize:'28px',fontFamily:'Arial Black',fill:'#ff3333',stroke:'#000',strokeThickness:5}).setOrigin(.5).setScrollFactor(0).setDepth(301);
    escena.add.text(ANCHO_VISTA/2,ALTO_VISTA/2,'PUNTOS: '+puntos,{fontSize:'20px',fontFamily:'Arial Black',fill:'#ffd700',stroke:'#000',strokeThickness:4}).setOrigin(.5).setScrollFactor(0).setDepth(301);
    const t=escena.add.text(ANCHO_VISTA/2,ALTO_VISTA/2+60,'Presioná ESPACIO, Z o clic para REINTENTAR',{fontSize:'16px',fontFamily:'Arial Black',fill:'#00ffcc',stroke:'#000',strokeThickness:3}).setOrigin(.5).setScrollFactor(0).setDepth(301);
    escena.tweens.add({targets:t,alpha:.3,duration:500,yoyo:true,repeat:-1});
    escena.time.delayedCall(500,()=>{const r=()=>escena.scene.restart();escena.input.keyboard.once('keydown-SPACE',r);escena.input.keyboard.once('keydown-Z',r);escena.input.keyboard.once('keydown-X',r);escena.input.keyboard.once('keydown-ENTER',r);escena.input.once('pointerdown',r);});
}

function llegarALaMeta(jugadorRef) {
    if(jefe?.active||juegoTerminado)return;
    juegoTerminado=true;jugador.setVelocity(0);jugador.anims.play('idle',true);AudioSFX.play('victoria');
    const escena=jugadorRef.scene;
    escena.add.rectangle(ANCHO_VISTA/2,ALTO_VISTA/2,ANCHO_VISTA,ALTO_VISTA,0x000,.85).setScrollFactor(0).setDepth(300);
    escena.add.text(ANCHO_VISTA/2,ALTO_VISTA/2-60,'¡NIVEL 1 COMPLETADO!\n¡RECETA DE LA EMPANADA SALVADA!',{fontSize:'26px',fontFamily:'Arial Black',fill:'#00ff66',stroke:'#000',strokeThickness:5,align:'center'}).setOrigin(.5).setScrollFactor(0).setDepth(301);
    escena.add.text(ANCHO_VISTA/2,ALTO_VISTA/2+10,'PUNTOS TOTALES: '+puntos,{fontSize:'22px',fontFamily:'Arial Black',fill:'#ffd700',stroke:'#000',strokeThickness:4}).setOrigin(.5).setScrollFactor(0).setDepth(301);
    const t=escena.add.text(ANCHO_VISTA/2,ALTO_VISTA/2+70,'Presioná ESPACIO para VOLVER A JUGAR',{fontSize:'16px',fontFamily:'Arial Black',fill:'#00ffcc',stroke:'#000',strokeThickness:3}).setOrigin(.5).setScrollFactor(0).setDepth(301);
    escena.tweens.add({targets:t,alpha:.3,duration:500,yoyo:true,repeat:-1});
    escena.time.delayedCall(500,()=>{const r=()=>escena.scene.restart();escena.input.keyboard.once('keydown-SPACE',r);escena.input.once('pointerdown',r);});
}
