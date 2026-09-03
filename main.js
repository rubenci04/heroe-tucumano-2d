// =============================================================================
// HÉROE TUCUMANO 2D ARCADE - ARCHIVO PRINCIPAL: main.js
// Modo 2.5D Estricto (2 Carriles), Cinemática de Prólogo, Ruta 38 Extendida,
// Exprebus, TESA, Insolación con Achilata y Jefe Palermitano.
// =============================================================================

const ANCHO_VISTA = 800;
const ALTO_VISTA = 450;
const ANCHO_MUNDO = 7200; // Nota para mí: Mundo extendido para recorrer toda la Ruta 38

// Nota para mí: Defino con precisión los dos carriles físicos para evitar bugs de flotación
const CARRIL_SUPERIOR_Y = 370;
const CARRIL_INFERIOR_Y = 422;
const Y_ESCENARIO = 345;

const config = {
    type: Phaser.AUTO,
    width: ANCHO_VISTA,
    height: ALTO_VISTA,
    parent: 'contenedor-juego',
    pixelArt: true,
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 1250 }, // Nota para mí: Gravedad alta para que los saltos caigan con peso arcade
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

// Variables de estado global
let jugador, cursores, teclaZ, teclaX;
let fondoCerros, fondoArboleda, sueloRuta, sueloRuta2;
let proyectilesJugador, proyectilesEnemigos, hipsters, agentes, grandotes, colectivos, empanadas, potenciadores, achilatas, metaFinal;
let vidas = 3, salud = 3;
const MAX_SALUD = 3;
let puntos = 0, armaActual = 'NINGUNA', municion = 0, modoSanguchazo = false;
let textoVidas, barraVidaGrafico, textoPuntos, textoArma, textoEspecial, textoVidaJefe, bannerNotificacion;
let esInvulnerable = false, disparoPresionado = false, disparando = false, juegoTerminado = false;

// Variables del sistema 2.5D
let estaSaltando = false;
let carrilActual = CARRIL_SUPERIOR_Y; // Nota para mí: Guarda el carril de apoyo real (370 o 422)
let cambiandoCarril = false;

// Variables del Jefe Final y Oleadas
let jefe, jefeActivo = false, vidaJefe = 45, jefeInvulnerable = false, jefeAtacando = false;
let oleadasActivadas = [];
let arbolSaqueado = false;
let cascotesLevantados = false;

// Variables de la Cinemática Inicial y Sistema de Insolación
let enCinematica = true;
let solSprite, barraCalorGrafico, textoCalor;
let nivelInsolacion = 0; // De 0 a 100
let insolacionActiva = false;
let tiempoUltimoDanioSol = 0;

function preload() {
    // Fondos de localidades y vegetación para el Parallax
    this.load.image('fondo_cerros', 'assets/fondo_cerros.png');
    this.load.image('fondo_arboleda', 'assets/fondo_arboleda.png');
    this.load.image('cañas', 'assets/cañas.png');
    this.load.image('acheral', 'assets/acheral.png');
    this.load.image('puente', 'assets/puente.png');
    this.load.image('monteros', 'assets/monteros.png');
    this.load.image('leon_rouges', 'assets/leon_rouges.png');
    this.load.image('villa_quinteros', 'assets/villa_quinteros.png');
    this.load.image('rio_seco', 'assets/rio_seco.png');
    this.load.image('ingenio', 'assets/ingenio.png');

    // Suelos de los dos carriles
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
    this.load.image('rastra_cañera', 'assets/rastra cañera.png');

    // Sprites de Cinemática
    this.load.image('ciruja_comiendo', 'assets/ciruja comiendo.png');
    this.load.image('campeona_empanadas', 'assets/campeona empanadas.png');
    this.load.image('secuestro_campeona', 'assets/secuestro_campeona.png');

    // Sprites del Jugador
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

    // Enemigos y Palermitano Malvado
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
    vidas = 3;
    salud = MAX_SALUD;
    puntos = 0;
    armaActual = 'NINGUNA';
    municion = 0;
    modoSanguchazo = false;
    disparando = false;
    esInvulnerable = false;
    estaSaltando = false;
    carrilActual = CARRIL_SUPERIOR_Y;
    cambiandoCarril = false;

    jefeActivo = false;
    vidaJefe = 45;
    jefeInvulnerable = false;
    jefeAtacando = false;
    oleadasActivadas = [];
    arbolSaqueado = false;
    cascotesLevantados = false;
    nivelInsolacion = 0;
    insolacionActiva = false;

    this.physics.world.setBounds(0, 0, ANCHO_MUNDO + 400, ALTO_VISTA);

    // =========================================================================
    // CAPAS PARALLAX Y FONDOS POR LOCALIDADES
    // =========================================================================
    fondoCerros = this.add.tileSprite(0, 0, ANCHO_VISTA, ALTO_VISTA, 'fondo_cerros').setOrigin(0, 0).setScrollFactor(0).setDepth(0);
    fondoArboleda = this.add.tileSprite(0, 0, ANCHO_VISTA, ALTO_VISTA, 'fondo_arboleda').setOrigin(0, 0).setScrollFactor(0).setDepth(1);

    // Fondos específicos de cada localidad a lo largo de los 7200 px
    this.add.image(1200, Y_ESCENARIO - 50, 'cañas').setOrigin(0.5, 1).setScale(1.1).setDepth(1.2);
    this.add.image(2100, Y_ESCENARIO - 50, 'acheral').setOrigin(0.5, 1).setScale(1.1).setDepth(1.2);
    this.add.image(2900, Y_ESCENARIO - 50, 'cañas').setOrigin(0.5, 1).setScale(1.1).setDepth(1.2);
    this.add.image(3600, Y_ESCENARIO - 50, 'puente').setOrigin(0.5, 1).setScale(1.2).setDepth(1.2);
    this.add.image(4300, Y_ESCENARIO - 50, 'monteros').setOrigin(0.5, 1).setScale(1.1).setDepth(1.2);
    this.add.image(5100, Y_ESCENARIO - 50, 'leon_rouges').setOrigin(0.5, 1).setScale(1.1).setDepth(1.2);
    this.add.image(5800, Y_ESCENARIO - 50, 'villa_quinteros').setOrigin(0.5, 1).setScale(1.1).setDepth(1.2);
    this.add.image(6400, Y_ESCENARIO - 50, 'rio_seco').setOrigin(0.5, 1).setScale(1.1).setDepth(1.2);
    this.add.image(7050, Y_ESCENARIO - 30, 'ingenio').setOrigin(0.5, 1).setScale(1.3).setDepth(1.2);

    // Los dos carriles de asfalto
    sueloRuta = this.add.tileSprite(0, Y_ESCENARIO - 20, ANCHO_VISTA, 160, 'suelo_ruta').setOrigin(0, 0).setScrollFactor(0).setDepth(1.5);
    sueloRuta2 = this.add.tileSprite(0, Y_ESCENARIO + 85, ANCHO_VISTA, 160, 'suelo_ruta2').setOrigin(0, 0).setScrollFactor(0).setDepth(1.6);

    // =========================================================================
    // ESCENOGRAFÍA Y VEHÍCULOS ESTÁTICOS DECORATIVOS
    // =========================================================================
    this.add.image(130, Y_ESCENARIO, 'cartel_famailla').setOrigin(0.5, 1).setScale(1.10).setDepth(2);
    this.add.image(350, Y_ESCENARIO, 'gruta_virgen').setOrigin(0.5, 1).setScale(0.72).setDepth(2);
    this.add.image(520, Y_ESCENARIO, 'arbol_naranjas').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    this.add.image(680, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);
    this.add.image(880, Y_ESCENARIO, 'kiosco_coca').setOrigin(0.5, 1).setScale(1.05).setDepth(2);

    // Autos estacionados en la banquina
    this.add.image(1600, CARRIL_SUPERIOR_Y - 20, 'auto1').setOrigin(0.5, 1).setScale(1.1).setDepth(CARRIL_SUPERIOR_Y - 5);
    this.add.image(3200, CARRIL_SUPERIOR_Y - 20, 'auto2').setOrigin(0.5, 1).setScale(1.1).setDepth(CARRIL_SUPERIOR_Y - 5);
    this.add.image(4700, CARRIL_SUPERIOR_Y - 20, 'auto3').setOrigin(0.5, 1).setScale(1.1).setDepth(CARRIL_SUPERIOR_Y - 5);
    this.add.image(2700, CARRIL_SUPERIOR_Y - 25, 'camion_limones').setOrigin(0.5, 1).setScale(1.2).setDepth(CARRIL_SUPERIOR_Y - 5);
    this.add.image(5400, CARRIL_SUPERIOR_Y - 25, 'rastra_cañera').setOrigin(0.5, 1).setScale(1.25).setDepth(CARRIL_SUPERIOR_Y - 5);

    // Postes de luz y vegetación distribuida
    [1000, 1800, 2600, 3400, 4200, 5000, 5800, 6600].forEach(px => {
        this.add.image(px, Y_ESCENARIO, 'poste_luz').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
        this.add.image(px + 300, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);
    });

    // =========================================================================
    // ANIMACIONES
    // =========================================================================
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
    this.anims.create({ key: 'grandote_punch', frames: [{ key: 'grandote_punch1' }, { key: 'grandote_punch2' }, { key: 'grandote_punch3' }], frameRate: 8, repeat: 0 });

    this.anims.create({ key: 'boss_run', frames: [{ key: 'final_boss_run1' }, { key: 'final_boss_run2' }, { key: 'final_boss_run3' }], frameRate: 10, repeat: -1 });
    this.anims.create({ key: 'boss_salto', frames: [{ key: 'final_boss_salto1' }, { key: 'final_boss_salto2' }], frameRate: 6, repeat: 0 });
    this.anims.create({ key: 'boss_punch', frames: [{ key: 'final_boss_punch1' }, { key: 'final_boss_punch2' }], frameRate: 8, repeat: 0 });
    this.anims.create({ key: 'boss_joke', frames: [{ key: 'final_boss_joke1' }, { key: 'final_boss_joke2' }], frameRate: 4, repeat: -1 });
    this.anims.create({ key: 'boss_cofee', frames: [{ key: 'final_boss_cofee1' }, { key: 'final_boss_cofee2' }], frameRate: 9, repeat: 0 });

    // =========================================================================
    // INSTANCIACIÓN DE ENTIDADES
    // =========================================================================
    jugador = this.physics.add.sprite(70, carrilActual, 'ciruja_idle');
    jugador.setScale(0.42);
    jugador.setCollideWorldBounds(true);
    jugador.setBounce(0);
    jugador.setDragX(1600);
    jugador.body.allowGravity = false; // Nota para mí: Controlamos la altura base manualmente en 2.5D

    this.cameras.main.setBounds(0, 0, ANCHO_MUNDO, ALTO_VISTA);
    this.cameras.main.startFollow(jugador, true, 0.08, 0.08);

    proyectilesJugador = this.physics.add.group({ allowGravity: false });
    proyectilesEnemigos = this.physics.add.group({ allowGravity: false });
    colectivos = this.physics.add.group();
    hipsters = this.physics.add.group();
    agentes = this.physics.add.group();
    grandotes = this.physics.add.group();
    achilatas = this.physics.add.group();

    this.physics.add.overlap(jugador, colectivos, manejarColisionColectivo, null, this);
    this.physics.add.overlap(proyectilesJugador, colectivos, impactarColectivo, null, this);

    // Nota para mí: El Palermitano Malvado ahora es mucho más grande (escala 0.78)
    jefe = this.physics.add.sprite(7050, CARRIL_INFERIOR_Y, 'final_boss_joke1');
    jefe.setScale(0.78);
    jefe.setCollideWorldBounds(true);
    jefe.body.allowGravity = false;
    jefe.anims.play('boss_joke', true);

    // Empanadas a lo largo de toda la travesía
    empanadas = this.physics.add.group();
    [240, 600, 1000, 1500, 2050, 2550, 3100, 3800, 4400, 5000, 5600, 6200, 6800].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let emp = empanadas.create(posX, carril, 'empanada');
        emp.setScale(0.14);
        emp.body.allowGravity = false;
        emp.postFX.addGlow(0xffd700, 2, 0, false);
    });

    // Achilatas para bajar la insolación en los tramos más calurosos (desde Monteros hacia el final)
    [3900, 4600, 5200, 5900, 6500].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let ach = achilatas.create(posX, carril, 'achilata');
        ach.setScale(0.35);
        ach.body.allowGravity = false;
        ach.postFX.addGlow(0xff00ff, 2, 0, false);
    });

    // Montaña de cascotes para abastecerse
    potenciadores = this.physics.add.group();
    let montañaCascote = potenciadores.create(1350, CARRIL_SUPERIOR_Y, 'montaña_cascote');
    montañaCascote.setScale(0.65);
    montañaCascote.body.allowGravity = false;
    montañaCascote.tipo = 'CASCOTES';

    let sangucheItem = potenciadores.create(4800, CARRIL_INFERIOR_Y, 'sanguche');
    sangucheItem.setScale(0.14);
    sangucheItem.body.allowGravity = false;
    sangucheItem.tipo = 'SANGUCHE';
    this.tweens.add({ targets: sangucheItem, scaleX: 0.16, scaleY: 0.16, duration: 400, yoyo: true, repeat: -1 });

    metaFinal = this.add.rectangle(7150, 400, 60, 140, 0x00ff00, 0);
    this.physics.add.existing(metaFinal, true);

    // Overlaps de combate y colisión
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

    // =========================================================================
    // HUD Y ELEMENTOS VISUALES EN PANTALLA
    // =========================================================================
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

    // Sistema de Insolación en pantalla
    solSprite = this.add.image(ANCHO_VISTA - 60, 60, 'sol').setScrollFactor(0).setScale(0.15).setAlpha(0).setDepth(99);
    barraCalorGrafico = this.add.graphics().setScrollFactor(0).setDepth(100);
    textoCalor = this.add.text(ANCHO_VISTA - 140, 95, '', { fontSize: '12px', fontFamily: 'Arial Black', fill: '#ffaa00', stroke: '#000000', strokeThickness: 3 }).setScrollFactor(0).setDepth(100);

    cursores = this.input.keyboard.createCursorKeys();
    teclaZ = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.Z);
    teclaX = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.X);

    this.time.addEvent({ delay: 2200, callback: ejecutarRutinaJefe, callbackScope: this, loop: true });

    // Iniciar la cinemática arcade
    ejecutarCinematicaPrologo(this);
}

function update(time, delta) {
    if (!jugador.active || juegoTerminado) return;

    // Scroll Parallax sincronizado con la cámara
    fondoCerros.tilePositionX = this.cameras.main.scrollX * 0.05;
    fondoArboleda.tilePositionX = this.cameras.main.scrollX * 0.25;
    sueloRuta.tilePositionX = this.cameras.main.scrollX * 1.0;
    sueloRuta2.tilePositionX = this.cameras.main.scrollX * 1.0;

    // Si estamos en la cinemática inicial, no se permite el control del usuario
    if (enCinematica) return;

    verificarProgresionOleadas(this);
    actualizarSistemaInsolacion(this, time);

    const velocidadBase = modoSanguchazo ? 330 : 230;

    // =========================================================================
    // MOVIMIENTO EN EJE X
    // =========================================================================
    if (cursores.left.isDown) {
        jugador.setVelocityX(-velocidadBase);
        jugador.setFlipX(true);
        if (!estaSaltando && !disparando) jugador.anims.play('correr', true);
    } else if (cursores.right.isDown) {
        jugador.setVelocityX(velocidadBase);
        jugador.setFlipX(false);
        if (!estaSaltando && !disparando) jugador.anims.play('correr', true);
    } else {
        jugador.setVelocityX(0);
        if (!estaSaltando && !disparando) jugador.anims.play('idle', true);
    }

    // =========================================================================
    // SISTEMA 2.5D: 2 CARRILES ESTRICTOS Y SALTO SIN FLOTACIÓN
    // =========================================================================
    if (!estaSaltando) {
        // Nota para mí: Cambio de carril limpio entre 370 y 422 para que nunca flote en coordenadas intermedias
        if (cursores.up.isDown && carrilActual === CARRIL_INFERIOR_Y && !cambiandoCarril) {
            cambiandoCarril = true;
            this.tweens.add({
                targets: jugador,
                y: CARRIL_SUPERIOR_Y,
                duration: 120,
                onComplete: () => {
                    carrilActual = CARRIL_SUPERIOR_Y;
                    cambiandoCarril = false;
                }
            });
        } else if (cursores.down.isDown && carrilActual === CARRIL_SUPERIOR_Y && !cambiandoCarril) {
            cambiandoCarril = true;
            this.tweens.add({
                targets: jugador,
                y: CARRIL_INFERIOR_Y,
                duration: 120,
                onComplete: () => {
                    carrilActual = CARRIL_INFERIOR_Y;
                    cambiandoCarril = false;
                }
            });
        }

        // Salto arcade
        if (Phaser.Input.Keyboard.JustDown(cursores.space)) {
            estaSaltando = true;
            jugador.body.allowGravity = true; // Activa gravedad para la parábola
            jugador.setVelocityY(-560);
            if (!disparando) jugador.anims.play('salto', true);
        }
    } else {
        // Nota para mí: Si empezó a caer y alcanzó o superó el carril activo, aterriza de inmediato
        if (jugador.body.velocity.y > 0 && jugador.y >= carrilActual) {
            jugador.y = carrilActual;
            jugador.body.allowGravity = false;
            jugador.setVelocityY(0);
            estaSaltando = false;
            jugador.anims.play('idle', true);
        }

        // Control de altura variable al soltar espacio
        if (cursores.space.isUp && jugador.body.velocity.y < -120) {
            jugador.setVelocityY(jugador.body.velocity.y * 0.55);
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

    actualizarColectivos();
    actualizarIAHipsters(this);
    actualizarIAAgentes(this);
    actualizarIAGrandotes(this);

    // Profundidad dinámica basada en el carril
    jugador.setDepth(carrilActual + (jugador.displayHeight * 0.5));
    hipsters.children.iterate(e => { if (e) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    agentes.children.iterate(e => { if (e) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    grandotes.children.iterate(e => { if (e) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    empanadas.children.iterate(e => { if (e) e.setDepth(e.y); });
    achilatas.children.iterate(e => { if (e) e.setDepth(e.y); });
    potenciadores.children.iterate(e => { if (e) e.setDepth(e.y); });
    if (jefe && jefe.active) jefe.setDepth(jefe.y + (jefe.displayHeight * 0.5));

    // Limpieza de proyectiles
    const margen = 120;
    proyectilesJugador.children.iterate((p) => {
        if (p && p.active) {
            p.angle += p.velocidadGiro;
            if (p.x < this.cameras.main.scrollX - margen || p.x > this.cameras.main.scrollX + ANCHO_VISTA + margen) {
                p.destroy();
            }
        }
    });

    proyectilesEnemigos.children.iterate((p) => {
        if (p && p.active) {
            p.angle += p.velocidadGiro || 0;
            if (p.x < this.cameras.main.scrollX - margen || p.x > this.cameras.main.scrollX + ANCHO_VISTA + margen) {
                p.destroy();
            }
        }
    });

    // Activar combate del Palermitano Malvado cerca del Ingenio
    if (jefe && jefe.active && !jefeActivo && jugador.x > 6750) {
        jefeActivo = true;
        actualizarBarraJefe();
    }
}

// =============================================================================
// CINEMÁTICA DE PRÓLOGO ESTILO ARCADE (METAL SLUG)
// =============================================================================
function ejecutarCinematicaPrologo(escena) {
    jugador.setVisible(false);

    // Props y personajes temporales para el prólogo en Famaillá
    let mesa = escena.add.image(190, CARRIL_SUPERIOR_Y, 'ciruja_comiendo').setScale(0.85).setDepth(50);
    let campeona = escena.add.image(280, CARRIL_SUPERIOR_Y - 5, 'campeona_empanadas').setScale(0.80).setDepth(50);

    let cajaTexto = escena.add.rectangle(ANCHO_VISTA / 2, ALTO_VISTA - 60, ANCHO_VISTA - 80, 70, 0x000000, 0.85).setScrollFactor(0).setDepth(200);
    let textoNarrado = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA - 60, 'FAMAILLÁ, CAPITAL DE LA EMPANADA.\nEL CIRUJA DISFRUTA DE UN MEDIODÍA DE PAZ...', {
        fontSize: '15px', fontFamily: 'Arial Black', fill: '#00ffcc', align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(201);

    // Paso 1: Paneo de cámara hacia adelante mostrando la tranquilidad
    escena.cameras.main.pan(500, ALTO_VISTA / 2, 2800, 'Sine.easeInOut');

    escena.time.delayedCall(3000, () => {
        escena.cameras.main.pan(250, ALTO_VISTA / 2, 1200, 'Sine.easeInOut');
        textoNarrado.setText('¡PERO LA PAZ SE TERMINA!\nEL PALERMITANO MALVADO APARECE CON SUS SECUACES...');
        textoNarrado.setFill('#ff3333');

        // Secuestro
        let raptores = escena.add.image(280, CARRIL_SUPERIOR_Y - 5, 'secuestro_campeona').setScale(0.85).setDepth(55);
        campeona.setVisible(false);

        escena.tweens.add({
            targets: raptores,
            x: 850,
            duration: 2500,
            ease: 'Linear'
        });
    });

    escena.time.delayedCall(6000, () => {
        textoNarrado.setText('¡SECUESTRARON A LA CAMPEONA!\nQUIEREN SERVIR LA EMPANADA EN FRASCO EN PALERMO...');
        textoNarrado.setFill('#ffff00');
    });

    escena.time.delayedCall(9000, () => {
        cajaTexto.destroy();
        textoNarrado.destroy();
        mesa.destroy();

        // Restaurar control al jugador
        jugador.setPosition(80, CARRIL_SUPERIOR_Y);
        jugador.setVisible(true);
        enCinematica = false;
        mostrarMensaje(escena, '¡SALVA LA RECETA TRADICIONAL!\nAVANZA POR LA RUTA 38');
    });
}

// =============================================================================
// SISTEMA DE INSOLACIÓN DINÁMICA (CALOR DE LA TARDE)
// =============================================================================
function actualizarSistemaInsolacion(escena, time) {
    // Se activa a partir de los 3500 px (Monteros en adelante)
    if (jugador.x > 3500) {
        if (!insolacionActiva) {
            insolacionActiva = true;
            solSprite.setAlpha(1);
            mostrarMensaje(escena, '¡EL SOL DE LA SIESTA APRIETA!\nBusca Achilatas para no insolarte');
        }

        // El sol crece y la insolación sube con el tiempo
        let factorCalor = Math.min(1, (jugador.x - 3500) / 3000);
        solSprite.setScale(0.15 + (factorCalor * 0.35));

        nivelInsolacion = Math.min(100, nivelInsolacion + 0.035);
        dibujarBarraInsolacion();

        // Daño periódico si la insolación llega al 100%
        if (nivelInsolacion >= 100 && time > tiempoUltimoDanioSol + 2500) {
            tiempoUltimoDanioSol = time;
            mostrarMensaje(escena, '¡ESTÁS INSOLADO! PIERDES ENERGÍA');
            recibirDanioJugador(escena);
        }
    }
}

function dibujarBarraInsolacion() {
    barraCalorGrafico.clear();
    if (!insolacionActiva) return;

    const x = ANCHO_VISTA - 130;
    const y = 80;
    const ancho = 100;
    const alto = 10;

    barraCalorGrafico.lineStyle(2, 0x000000, 1);
    barraCalorGrafico.strokeRect(x, y, ancho, alto);

    let color = (nivelInsolacion > 75) ? 0xff0000 : (nivelInsolacion > 45) ? 0xffaa00 : 0xffff00;
    barraCalorGrafico.fillStyle(color, 1);
    barraCalorGrafico.fillRect(x, y, (ancho * (nivelInsolacion / 100)), alto);

    textoCalor.setText('INSOLACIÓN: ' + Math.floor(nivelInsolacion) + '%');
}

function recolectarAchilata(jugadorRef, achilata) {
    if (Math.abs(carrilActual - achilata.y) > 25) return;
    achilata.destroy();
    nivelInsolacion = Math.max(0, nivelInsolacion - 40);
    puntos += 100;
    dibujarBarraInsolacion();
    actualizarHUD();
    mostrarMensaje(jugadorRef.scene, '¡QUÉ RICA ACHILATA!\nInsolación reducida');
}

// =============================================================================
// OLEADAS Y SPAWN DE COLECTIVOS (EXPREBUS Y TESA)
// =============================================================================
function verificarProgresionOleadas(escena) {
    if (!arbolSaqueado && jugador.x >= 480 && jugador.x <= 560) {
        arbolSaqueado = true;
        armaActual = 'NARANJA';
        municion = 999;
        actualizarHUD();
        mostrarMensaje(escena, '¡HAS CHOREADO NARANJAS!\nPuedes usarlas como arma');
    }

    const oleadas = [
        {
            id: 1, triggerX: 620, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', -65);
                spawnEnemigo(escena, 'HIPSTER', 0);
                spawnEnemigo(escena, 'HIPSTER', 500);
            }
        },
        {
            id: 2, triggerX: 1600, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', -60);
                spawnEnemigo(escena, 'AGENTE', 0);
                spawnEnemigo(escena, 'HIPSTER', 600);
            }
        },
        {
            id: 3, triggerX: 2500, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', -65);
                spawnEnemigo(escena, 'AGENTE', 0);
                spawnEnemigo(escena, 'GRANDOTE', 600);
            }
        },
        {
            id: 4, triggerX: 3700, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', -60);
                spawnEnemigo(escena, 'GRANDOTE', 0);
                spawnEnemigo(escena, 'AGENTE', 500);
            }
        },
        {
            id: 5, triggerX: 5100, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', -65);
                spawnEnemigo(escena, 'GRANDOTE', 0);
                spawnEnemigo(escena, 'AGENTE', 700);
                spawnEnemigo(escena, 'HIPSTER', 1200);
            }
        },
        {
            id: 6, triggerX: 6300, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', -65);
                spawnEnemigo(escena, 'GRANDOTE', 0);
                spawnEnemigo(escena, 'GRANDOTE', 800);
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

function spawnEnemigo(escena, tipo, retrasoMs) {
    escena.time.delayedCall(retrasoMs, () => {
        let posX = escena.cameras.main.scrollX + ANCHO_VISTA + 60;
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;

        if (tipo === 'HIPSTER') {
            let h = hipsters.create(posX, carril, 'hipster_agua1');
            h.setScale(0.40);
            h.tipo = 'HIPSTER';
            h.vida = 3;
            h.puntosValor = 75;
            h.invulnerable = false;
            h.ultimoAtaque = escena.time.now + Phaser.Math.Between(800, 1600);
            h.body.allowGravity = false;
        } else if (tipo === 'AGENTE') {
            let a = agentes.create(posX, carril, 'agente_run1');
            a.setScale(0.40);
            a.tipo = 'AGENTE';
            a.vida = 5;
            a.puntosValor = 150;
            a.invulnerable = false;
            a.ultimoDisparo = escena.time.now + Phaser.Math.Between(600, 1400);
            a.body.allowGravity = false;
        } else if (tipo === 'GRANDOTE') {
            let g = grandotes.create(posX, carril, 'grandote_run1');
            // Nota para mí: Grandote con escala aumentada a 0.72
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

function lanzarColectivo(escena, x, spriteKey, velocidad) {
    let carrilY = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y + 15 : CARRIL_INFERIOR_Y + 10;
    let bus = colectivos.create(x, carrilY, spriteKey);
    bus.setOrigin(0.5, 1);
    bus.setScale(1.70);
    bus.setDepth(carrilY);
    bus.vida = 8;
    bus.velocidadX = velocidad;
    bus.averiado = false;
    bus.setImmovable(true);
    bus.body.allowGravity = false;

    let anchoReal = bus.displayWidth * 0.82;
    let altoReal = bus.displayHeight * 0.88;
    bus.body.setSize(anchoReal, altoReal);
    bus.body.setOffset((bus.displayWidth - anchoReal) / 2, bus.displayHeight - altoReal);

    escena.tweens.add({
        targets: bus, y: carrilY - 2, duration: 180, yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
    });
}

function actualizarColectivos() {
    colectivos.children.iterate((bus) => {
        if (!bus || !bus.active) return;
        if (!bus.averiado) {
            bus.setVelocityX(bus.velocidadX);
        } else {
            bus.setVelocityX(0);
        }
    });
}

function manejarColisionColectivo(jugadorRef, bus) {
    if (jugadorRef.y < bus.body.top) return; // Si salta por encima no choca
    if (Math.abs(carrilActual - bus.y) > 35) return; // Si está en el otro carril pasa libre

    if (!bus.averiado) {
        recibirDanioJugador(jugadorRef.scene);
    }
}

function impactarColectivo(proyectil, bus) {
    if (!bus || !bus.active || bus.averiado) return;
    if (Math.abs(proyectil.y - (bus.y - bus.displayHeight / 2)) > 65) return;

    let danio = (armaActual === 'CASCOTE') ? 3 : 1;
    bus.vida -= danio;
    proyectil.destroy();
    bus.setTint(0xff2222);

    bus.scene.time.delayedCall(120, () => {
        if (bus && bus.active && !bus.averiado) bus.clearTint();
    });

    if (bus.vida <= 0) {
        bus.averiado = true;
        bus.setTint(0x666666);
        puntos += 250;
        actualizarHUD();

        let txtAveriado = bus.scene.add.text(bus.x, bus.y - 130, '¡MOTOR REVENTADO!', {
            fontSize: '14px', fontFamily: 'Arial Black', fill: '#ffaa00', stroke: '#000000', strokeThickness: 3
        }).setOrigin(0.5).setDepth(100);

        bus.scene.tweens.add({
            targets: txtAveriado, y: txtAveriado.y - 30, alpha: 0, duration: 800, onComplete: () => txtAveriado.destroy()
        });
    }
}

// =============================================================================
// SISTEMA DE DISPARO DEL JUGADOR
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

    let spawnX = jugador.x + (dirX * 8);
    let spawnY = jugador.y - 4;
    let proyectil = proyectilesJugador.create(spawnX, spawnY, spriteProyectil);
    proyectil.setScale(escalaProyectil);
    proyectil.setDepth(carrilActual + (jugador.displayHeight * 0.5));
    proyectil.setVelocity(dirX * velocidadProyectil, 0);
    proyectil.velocidadGiro = (dirX !== 0 ? dirX : 1) * 20;

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
// COMPORTAMIENTOS E IA DE ENEMIGOS
// =============================================================================
function actualizarIAHipsters(escena) {
    hipsters.children.iterate((hipster) => {
        if (!hipster || !hipster.active) return;
        let dist = Math.abs(hipster.x - jugador.x);
        hipster.setVelocityX(-65);
        hipster.anims.play('hipster_run', true);

        if (dist < 750 && escena.time.now > hipster.ultimoAtaque + 2500) {
            if (Math.abs(carrilActual - hipster.y) < 40) {
                hipster.ultimoAtaque = escena.time.now;
                hipster.anims.play('hipster_lanzar', true);

                let botella = proyectilesEnemigos.create(hipster.x - 16, hipster.y - 6, 'botella_agua');
                botella.setScale(0.14);
                botella.setDepth(hipster.y + (hipster.displayHeight * 0.5));
                botella.setVelocity(-250, 0);
                botella.velocidadGiro = -16;
            }
        }
    });
}

function actualizarIAAgentes(escena) {
    agentes.children.iterate((agente) => {
        if (!agente || !agente.active) return;
        let dist = Math.abs(agente.x - jugador.x);
        if (dist > 160) {
            agente.setVelocityX(-75);
            agente.anims.play('agente_run', true);
        } else {
            agente.setVelocityX(0);
        }

        if (dist < 800 && escena.time.now > agente.ultimoDisparo + 2200) {
            if (Math.abs(carrilActual - agente.y) < 40) {
                agente.ultimoDisparo = escena.time.now;
                agente.anims.play('agente_disparar', true);

                let bala = proyectilesEnemigos.create(agente.x - 20, agente.y - 6, 'bala');
                bala.setScale(0.20);
                bala.setDepth(agente.y + (agente.displayHeight * 0.5));
                bala.setVelocity(-300, 0);
            }
        }
    });
}

function actualizarIAGrandotes(escena) {
    grandotes.children.iterate((grandote) => {
        if (!grandote || !grandote.active) return;
        if (grandote.atacandoCuerpoACuerpo) return;

        let dist = Math.abs(grandote.x - jugador.x);
        if (dist < 600) {
            if (dist < 75 && Math.abs(carrilActual - grandote.y) < 30) {
                grandote.atacandoCuerpoACuerpo = true;
                grandote.setVelocityX(0);
                grandote.anims.play('grandote_punch', true);

                escena.time.delayedCall(350, () => {
                    if (grandote && grandote.active && Math.abs(grandote.x - jugador.x) < 85 && Math.abs(carrilActual - grandote.y) < 30) {
                        recibirDanioJugador(escena);
                    }
                });

                escena.time.delayedCall(700, () => {
                    if (grandote && grandote.active) {
                        grandote.atacandoCuerpoACuerpo = false;
                    }
                });
                return;
            }
            grandote.setVelocityX(-100);
            grandote.anims.play('grandote_run', true);
        } else {
            grandote.setVelocityX(-100);
            grandote.anims.play('grandote_run', true);
        }
    });
}

function impactarEnemigo(proyectil, enemigo) {
    if (Math.abs(proyectil.y - enemigo.y) > 40) return;
    proyectil.destroy();
    if (enemigo.invulnerable) return;

    let danio = (armaActual === 'CASCOTE') ? 3 : 1;
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
// JEFE FINAL (PALERMITANO MALVADO)
// =============================================================================
function ejecutarRutinaJefe() {
    if (!jefe || !jefe.active || !jefeActivo || jefeAtacando || juegoTerminado) return;
    jefeAtacando = true;
    jefe.setFlipX(false);
    let ataqueAleatorio = Math.random();

    if (ataqueAleatorio < 0.45) {
        jefe.anims.play('boss_cofee', true);
        jefe.setVelocityX(0);
        this.time.delayedCall(300, () => {
            if (jefe && jefe.active) {
                lanzarVasoCafe(this, jefe.x - 30, jefe.y - 10, -340, 0);
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
        jefe.setVelocityX(-220);
        this.time.delayedCall(450, () => {
            if (jefe && jefe.active) {
                jefe.setVelocityX(0);
                jefe.anims.play('boss_cofee', true);
                lanzarVasoCafe(this, jefe.x - 30, jefe.y - 10, -420, 0);
            }
        });
        this.time.delayedCall(950, () => {
            if (jefe && jefe.active) {
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
    if (Math.abs(proyectil.y - jefeRef.y) > 50) return;
    proyectil.destroy();
    if (jefeInvulnerable || !jefeActivo) return;

    let danio = (armaActual === 'CASCOTE') ? 3 : 1;
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
    const bloques = Math.max(0, Math.ceil(vidaJefe / 2));
    textoVidaJefe.setText('PALERMITANO MALVADO: ' + '█'.repeat(bloques));
}

function derrotarJefe(escena) {
    puntos += 1500;
    actualizarHUD();
    textoVidaJefe.setText('¡RECETA SALVADA!');
    escena.tweens.add({
        targets: jefe, angle: 180, y: jefe.y - 80, alpha: 0, duration: 900, onComplete: () => jefe.destroy()
    });
}

function interaccionJugadorEnemigo(jugadorRef, enemigo) {
    if (Math.abs(carrilActual - enemigo.y) > 30) return;
    if (modoSanguchazo) {
        enemigo.destroy();
        puntos += 100;
        actualizarHUD();
        return;
    }
    recibirDanioJugador(jugadorRef.scene);
}

function interaccionJugadorJefe(jugadorRef, jefeRef) {
    if (Math.abs(carrilActual - jefeRef.y) > 35) return;
    if (modoSanguchazo) {
        impactarJefe({ destroy: () => { }, y: jugadorRef.y }, jefeRef);
        return;
    }
    recibirDanioJugador(jugadorRef.scene);
}

function impactarJugadorConProyectilEnemigo(jugadorRef, proyectil) {
    if (Math.abs(carrilActual - proyectil.y) > 30) return;
    proyectil.destroy();
    recibirDanioJugador(jugadorRef.scene);
}

// =============================================================================
// SALUD (3 IMPACTOS POR VIDA)
// =============================================================================
function recibirDanioJugador(escena) {
    if (esInvulnerable || juegoTerminado) return;
    salud -= 1;
    if (salud <= 0) {
        vidas -= 1;
        salud = MAX_SALUD;
    }
    actualizarHUD();

    if (vidas <= 0) {
        juegoTerminado = true;
        jugador.setVelocity(0, 0);
        jugador.setTint(0xff0000);
        alert('¡Te liquidaron en la ruta! Reiniciando...');
        location.reload();
    } else {
        esInvulnerable = true;
        jugador.setVelocityY(-220);
        jugador.setVelocityX(jugador.flipX ? 150 : -150);

        let parpadeos = 0;
        escena.time.addEvent({
            delay: 100, repeat: 7, callback: () => {
                jugador.alpha = (jugador.alpha === 1) ? 0.3 : 1;
                parpadeos++;
                if (parpadeos >= 8) {
                    jugador.alpha = 1;
                    esInvulnerable = false;
                }
            }
        });
    }
}

// =============================================================================
// RECOLECCIÓN Y POTENCIADORES
// =============================================================================
function recolectarEmpanada(jugadorRef, empanada) {
    if (Math.abs(carrilActual - empanada.y) > 25) return;
    empanada.destroy();
    puntos += 25;
    actualizarHUD();
}

function recolectarPotenciador(jugadorRef, item) {
    if (Math.abs(carrilActual - item.y) > 30) return;
    if (item.tipo === 'SANGUCHE') {
        activarModoSanguchazo(jugadorRef.scene);
    } else if (item.tipo === 'CASCOTES') {
        if (!cascotesLevantados) {
            cascotesLevantados = true;
            armaActual = 'CASCOTE';
            municion = 20;
            actualizarHUD();
            mostrarMensaje(jugadorRef.scene, '¡ENCONTRASTE UN MONTÓN DE CASCOTES!\nAhora tienes munición pesada');
        }
    }
    item.destroy();
}

function activarModoSanguchazo(escena) {
    modoSanguchazo = true;
    textoEspecial.setText('¡FURIA DE MILANGA: CABEZAZO ACTIVADO!');
    jugador.setTint(0xffd700);
    escena.time.delayedCall(8000, () => {
        modoSanguchazo = false;
        textoEspecial.setText('');
        jugador.clearTint();
    });
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
        duration: 150,
        yoyo: true,
        onComplete: () => {
            scene.tweens.add({
                targets: bannerNotificacion,
                alpha: 0,
                delay: 2000,
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

    jugadorRef.scene.add.text(ANCHO_VISTA / 2, ALTO_VISTA / 2, '¡NIVEL 1 COMPLETADO!\nENTRANDO AL INGENIO...', {
        fontSize: '36px', fontFamily: 'Arial Black', fill: '#00ff66', stroke: '#000000', strokeThickness: 6, align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(200);

    setTimeout(() => { location.reload(); }, 3500);
}