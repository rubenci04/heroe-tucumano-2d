// =============================================================================
// HÉROE TUCUMANO 2D ARCADE - ARCHIVO PRINCIPAL: main.js
// Mejoras: Naranjo/Cascotes latentes, IA con detención de disparo,
// Puñetazos del Grandote, Tráfico de Autos en Ruta, Buses Imponentes y Transiciones.
// =============================================================================

const ANCHO_VISTA = 800;
const ALTO_VISTA = 450;
const ANCHO_MUNDO = 14400;

// Carriles 2.5D
const CARRIL_SUPERIOR_Y = 370;
const CARRIL_INFERIOR_Y = 420;
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
let jugador, cursores, teclaZ, teclaX;
let fondoCerros, fondoArboleda, sueloRuta, sueloRuta2;
let proyectilesJugador, proyectilesEnemigos, hipsters, agentes, grandotes, colectivos, autosRuta, empanadas, potenciadores, achilatas, metaFinal;
let vidas = 3, salud = 3;
const MAX_SALUD = 3;
let puntos = 0, armaActual = 'NINGUNA', municion = 0, modoSanguchazo = false;
let textoVidas, barraVidaGrafico, textoPuntos, textoArma, textoEspecial, textoVidaJefe, bannerNotificacion;
let esInvulnerable = false, disparoPresionado = false, disparando = false, juegoTerminado = false;

// Variables de salto y carril 2.5D
let estaSaltando = false;
let carrilActual = CARRIL_SUPERIOR_Y;

// Variables del Jefe Final y Progresión
let jefe, jefeActivo = false, vidaJefe = 45, jefeInvulnerable = false, jefeAtacando = false;
let oleadasActivadas = [];
let arbolSaqueado = false;
let cascotesLevantados = false;
let arbolNaranjasIntro, monticuloCascotesVisual;

// Variables de Cinemática e Insolación
let enCinematica = true;
let solSprite, barraCalorGrafico, textoCalor, capaTinteCalor;
let nivelInsolacion = 0;
let insolacionActiva = false;
let tiempoUltimoDanioSol = 0;

function preload() {
    // Fondos de localidades para el Parallax
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

    // Fondos Parallax
    fondoCerros = this.add.tileSprite(0, 0, ANCHO_VISTA, ALTO_VISTA, 'fondo_cerros')
        .setOrigin(0, 0).setScrollFactor(0).setDepth(0);

    fondoArboleda = this.add.tileSprite(0, 0, ANCHO_VISTA, ALTO_VISTA, 'fondo_arboleda')
        .setOrigin(0, 0).setScrollFactor(0).setDepth(1);

    // =========================================================================
    // FONDOS EXTENDIDOS CON TRANSICIÓN SUAVE (DIFUMINADO)
    // =========================================================================
    crearFondoConTransicion(this, 1900, 'cañas', 900);
    crearFondoConTransicion(this, 2750, 'cañas', 900);

    crearFondoConTransicion(this, 3600, 'acheral', 900);
    crearFondoConTransicion(this, 4450, 'acheral', 900);

    crearFondoConTransicion(this, 5300, 'cañas', 850);
    crearFondoConTransicion(this, 6100, 'cañas', 850);

    crearFondoConTransicion(this, 6900, 'puente', 850);
    crearFondoConTransicion(this, 7700, 'monteros', 900);
    crearFondoConTransicion(this, 8550, 'monteros', 900);

    crearFondoConTransicion(this, 9400, 'leon_rouges', 900);
    crearFondoConTransicion(this, 10250, 'leon_rouges', 900);

    // Villa Quinteros: encuadre limpio sin cortes
    crearFondoConTransicion(this, 11100, 'villa_quinteros', 950);
    crearFondoConTransicion(this, 12000, 'villa_quinteros', 950);

    crearFondoConTransicion(this, 12900, 'rio_seco', 850);
    crearFondoConTransicion(this, 13700, 'ingenio', 900);

    // Carretera con sus dos carriles
    sueloRuta = this.add.tileSprite(0, Y_ESCENARIO - 20, ANCHO_VISTA, 160, 'suelo_ruta').setOrigin(0, 0).setScrollFactor(0).setDepth(1.5);
    sueloRuta2 = this.add.tileSprite(0, Y_ESCENARIO + 85, ANCHO_VISTA, 160, 'suelo_ruta2').setOrigin(0, 0).setScrollFactor(0).setDepth(1.6);

    // =========================================================================
    // ESCENOGRAFÍA Y PROPS (SIN PALMERAS FUERA DE FAMAILLÁ)
    // =========================================================================
    this.add.image(130, Y_ESCENARIO, 'cartel_famailla').setOrigin(0.5, 1).setScale(1.10).setDepth(2);
    this.add.image(350, Y_ESCENARIO, 'gruta_virgen').setOrigin(0.5, 1).setScale(0.72).setDepth(2);

    // Nota para mí: Naranjo inicial con brillo y latido visual continuo
    arbolNaranjasIntro = this.add.image(520, Y_ESCENARIO, 'arbol_naranjas').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    this.tweens.add({
        targets: arbolNaranjasIntro,
        scaleX: 0.90,
        scaleY: 0.90,
        duration: 550,
        yoyo: true,
        repeat: -1,
        ease: 'Sine.easeInOut'
    });

    // Palmeras exclusivas de Famaillá
    this.add.image(680, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);
    this.add.image(880, Y_ESCENARIO, 'kiosco_coca').setOrigin(0.5, 1).setScale(1.05).setDepth(2);
    this.add.image(1250, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);
    this.add.image(1650, Y_ESCENARIO, 'palmera').setOrigin(0.5, 1).setScale(0.90).setDepth(2);

    // Paradas de colectivo y naranjos en la ruta
    [2400, 4100, 5800, 7300, 9050, 10800, 12500].forEach(px => {
        this.add.image(px, Y_ESCENARIO, 'parada_colectivo').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
        this.add.image(px + 450, Y_ESCENARIO, 'arbol_naranjas').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
    });

    // Postes de luz reubicados en los laterales de los objetos (sin superponerse)
    const posicionesPostes = [1050, 1450, 2150, 2650, 3850, 4350, 5550, 6050, 7050, 7550, 8750, 9300, 10500, 11050, 12250, 12750];
    posicionesPostes.forEach(px => {
        this.add.image(px, Y_ESCENARIO, 'poste_luz').setOrigin(0.5, 1).setScale(0.85).setDepth(2);
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
    this.anims.create({ key: 'grandote_punch', frames: [{ key: 'grandote_punch1' }, { key: 'grandote_punch2' }, { key: 'grandote_punch3' }], frameRate: 9, repeat: 0 });

    this.anims.create({ key: 'boss_run', frames: [{ key: 'final_boss_run1' }, { key: 'final_boss_run2' }, { key: 'final_boss_run3' }], frameRate: 10, repeat: -1 });
    this.anims.create({ key: 'boss_salto', frames: [{ key: 'final_boss_salto1' }, { key: 'final_boss_salto2' }], frameRate: 6, repeat: 0 });
    this.anims.create({ key: 'boss_punch', frames: [{ key: 'final_boss_punch1' }, { key: 'final_boss_punch2' }], frameRate: 8, repeat: 0 });
    this.anims.create({ key: 'boss_joke', frames: [{ key: 'final_boss_joke1' }, { key: 'final_boss_joke2' }], frameRate: 4, repeat: -1 });
    this.anims.create({ key: 'boss_cofee', frames: [{ key: 'final_boss_cofee1' }, { key: 'final_boss_cofee2' }], frameRate: 9, repeat: 0 });

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
    this.cameras.main.startFollow(jugador, true, 0.08, 0.08);

    proyectilesJugador = this.physics.add.group({ allowGravity: false });
    proyectilesEnemigos = this.physics.add.group({ allowGravity: false });
    colectivos = this.physics.add.group();
    autosRuta = this.physics.add.group();
    hipsters = this.physics.add.group();
    agentes = this.physics.add.group();
    grandotes = this.physics.add.group();
    achilatas = this.physics.add.group();

    // Colisiones con vehículos
    this.physics.add.overlap(jugador, colectivos, manejarColisionVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, colectivos, impactarVehiculo, null, this);
    this.physics.add.overlap(jugador, autosRuta, manejarColisionVehiculo, null, this);
    this.physics.add.overlap(proyectilesJugador, autosRuta, impactarVehiculo, null, this);

    // Autos integrados en la calzada (quietos y en movimiento)
    crearAutoEnRuta(this, 3100, CARRIL_SUPERIOR_Y, 'auto1', 0); // Estacionado
    crearAutoEnRuta(this, 5400, CARRIL_INFERIOR_Y, 'camion_limones', -35); // En marcha lenta
    crearAutoEnRuta(this, 8100, CARRIL_SUPERIOR_Y, 'auto2', 0); // Estacionado
    crearAutoEnRuta(this, 10400, CARRIL_INFERIOR_Y, 'auto3', -45); // En marcha

    // Jefe Palermitano Malvado esperando en el Ingenio
    jefe = this.physics.add.sprite(14050, CARRIL_INFERIOR_Y, 'final_boss_joke1');
    jefe.setScale(0.78);
    jefe.setCollideWorldBounds(true);
    jefe.body.allowGravity = false;
    jefe.anims.play('boss_joke', true);

    // Empanadas
    empanadas = this.physics.add.group();
    [240, 750, 1400, 2200, 3100, 3900, 4800, 5600, 6500, 7400, 8300, 9200, 10100, 11000, 11900, 12800, 13700].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let emp = empanadas.create(posX, carril, 'empanada');
        emp.setScale(0.14);
        emp.body.allowGravity = false;
        emp.postFX.addGlow(0xffd700, 2, 0, false);
    });

    // Achilatas más proporcionadas (escala 0.22)
    [5800, 6900, 8200, 9500, 10900, 12100, 13200].forEach(posX => {
        let carril = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y : CARRIL_INFERIOR_Y;
        let ach = achilatas.create(posX, carril, 'achilata');
        ach.setScale(0.22);
        ach.body.allowGravity = false;
        ach.postFX.addGlow(0xff00ff, 2, 0, false);
    });

    // Montañas de cascotes con latido pulsante
    potenciadores = this.physics.add.group();
    let montaña1 = potenciadores.create(1550, CARRIL_SUPERIOR_Y, 'montaña_cascote');
    montaña1.setScale(0.65);
    montaña1.body.allowGravity = false;
    montaña1.tipo = 'CASCOTES';
    this.tweens.add({ targets: montaña1, scaleX: 0.70, scaleY: 0.70, duration: 500, yoyo: true, repeat: -1 });

    let montaña2 = potenciadores.create(7200, CARRIL_SUPERIOR_Y, 'montaña_cascote');
    montaña2.setScale(0.65);
    montaña2.body.allowGravity = false;
    montaña2.tipo = 'CASCOTES';
    this.tweens.add({ targets: montaña2, scaleX: 0.70, scaleY: 0.70, duration: 500, yoyo: true, repeat: -1 });

    // Sánguche de milanesa más grande (escala 0.25)
    let sangucheItem = potenciadores.create(9600, CARRIL_INFERIOR_Y, 'sanguche');
    sangucheItem.setScale(0.25);
    sangucheItem.body.allowGravity = false;
    sangucheItem.tipo = 'SANGUCHE';
    this.tweens.add({ targets: sangucheItem, scaleX: 0.28, scaleY: 0.28, duration: 400, yoyo: true, repeat: -1 });

    metaFinal = this.add.rectangle(14300, 400, 60, 140, 0x00ff00, 0);
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

    this.time.addEvent({ delay: 2200, callback: ejecutarRutinaJefe, callbackScope: this, loop: true });

    ejecutarCinematicaPrologo(this);
}

function update(time, delta) {
    if (!jugador.active || juegoTerminado) return;

    fondoCerros.tilePositionX = this.cameras.main.scrollX * 0.05;
    fondoArboleda.tilePositionX = this.cameras.main.scrollX * 0.25;
    sueloRuta.tilePositionX = this.cameras.main.scrollX * 1.0;
    sueloRuta2.tilePositionX = this.cameras.main.scrollX * 1.0;

    if (enCinematica) return;

    verificarProgresionOleadas(this);
    actualizarSistemaInsolacion(this, time);

    const velocidadBase = modoSanguchazo ? 330 : 230;

    // Movimiento horizontal en X
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

    // Control de carril 2.5D
    if (!estaSaltando) {
        jugador.body.allowGravity = false;
        jugador.setVelocityY(0);

        if (Phaser.Input.Keyboard.JustDown(cursores.up) && carrilActual === CARRIL_INFERIOR_Y) {
            carrilActual = CARRIL_SUPERIOR_Y;
            jugador.y = CARRIL_SUPERIOR_Y;
        } else if (Phaser.Input.Keyboard.JustDown(cursores.down) && carrilActual === CARRIL_SUPERIOR_Y) {
            carrilActual = CARRIL_INFERIOR_Y;
            jugador.y = CARRIL_INFERIOR_Y;
        }

        if (Phaser.Input.Keyboard.JustDown(cursores.space)) {
            estaSaltando = true;
            jugador.body.allowGravity = true;
            jugador.setVelocityY(-580);
            if (!disparando) jugador.anims.play('salto', true);
        }
    } else {
        if (jugador.body.velocity.y > 0 && jugador.y >= carrilActual) {
            jugador.y = carrilActual;
            jugador.body.allowGravity = false;
            jugador.setVelocityY(0);
            estaSaltando = false;
            jugador.anims.play('idle', true);
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

    actualizarColectivos();
    actualizarAutosRuta();
    actualizarIAHipsters(this);
    actualizarIAAgentes(this);
    actualizarIAGrandotes(this);

    // Profundidad dinámica
    jugador.setDepth(carrilActual + (jugador.displayHeight * 0.5));
    hipsters.children.iterate(e => { if (e) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    agentes.children.iterate(e => { if (e) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    grandotes.children.iterate(e => { if (e) e.setDepth(e.y + (e.displayHeight * 0.5)); });
    autosRuta.children.iterate(a => { if (a) a.setDepth(a.y); });
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

    if (jefe && jefe.active && !jefeActivo && jugador.x > 13800) {
        jefeActivo = true;
        actualizarBarraJefe();
    }
}

// =============================================================================
// HELPER PARA TRANSICIÓN DE FONDOS CON DIFUMINADO
// =============================================================================
function crearFondoConTransicion(escena, posX, spriteKey, anchoCustom) {
    let ancho = anchoCustom || 850;
    let img = escena.add.image(posX, 0, spriteKey)
        .setOrigin(0, 0)
        .setDisplaySize(ancho, ALTO_VISTA)
        .setDepth(1.2);

    // Nota para mí: Creo un suave fundido al inicio de la imagen para que no corte tajante con el fondo previo
    let sombraTransicion = escena.add.rectangle(posX + 40, ALTO_VISTA / 2, 80, ALTO_VISTA, 0x000000, 0.12)
        .setOrigin(0.5, 0.5)
        .setDepth(1.25);

    return img;
}

// =============================================================================
// CINEMÁTICA OFICIAL: EL PALERMITANO AL MANDO
// =============================================================================
function ejecutarCinematicaPrologo(escena) {
    jugador.setVisible(false);

    let mesa = escena.add.image(190, CARRIL_SUPERIOR_Y, 'ciruja_comiendo').setScale(0.85).setDepth(50);
    let campeona = escena.add.image(290, CARRIL_SUPERIOR_Y - 5, 'campeona_empanadas').setScale(0.80).setDepth(50);

    let cajaTexto = escena.add.rectangle(ANCHO_VISTA / 2, ALTO_VISTA - 60, ANCHO_VISTA - 80, 70, 0x000000, 0.85).setScrollFactor(0).setDepth(200);
    let textoNarrado = escena.add.text(ANCHO_VISTA / 2, ALTO_VISTA - 60, 'FAMAILLÁ, CAPITAL DE LA EMPANADA.\nEL CIRUJA DISFRUTA DE UN MEDIODÍA DE PAZ...', {
        fontSize: '15px', fontFamily: 'Arial Black', fill: '#00ffcc', align: 'center'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(201);

    escena.cameras.main.pan(500, ALTO_VISTA / 2, 2800, 'Sine.easeInOut');

    escena.time.delayedCall(3000, () => {
        escena.cameras.main.pan(320, ALTO_VISTA / 2, 1000, 'Sine.easeInOut');
        textoNarrado.setText('¡ATAQUE SORPRESA!\nLOS AGENTES PALERMITANOS ATRAPAN A LA CAMPEONA...');
        textoNarrado.setFill('#ff3333');

        campeona.destroy();

        let raptores = escena.add.image(290, CARRIL_SUPERIOR_Y - 5, 'secuestro_campeona').setScale(0.85).setDepth(55);
        let palermitanoJefeIntro = escena.add.sprite(200, CARRIL_SUPERIOR_Y - 10, 'final_boss_joke1').setScale(0.75).setDepth(56);
        palermitanoJefeIntro.anims.play('boss_joke', true);

        escena.time.delayedCall(2200, () => {
            textoNarrado.setText('PALERMITANO MALVADO: "¡LLEVENLA A PALERMO!\n¡VAMOS A SERVIR LA EMPANADA DECONSTRUIDA EN FRASCO!"');
            textoNarrado.setFill('#ffff00');

            escena.tweens.add({
                targets: raptores,
                x: 1100,
                duration: 2600,
                ease: 'Linear'
            });

            escena.time.delayedCall(500, () => {
                palermitanoJefeIntro.anims.play('boss_run', true);
                escena.tweens.add({
                    targets: palermitanoJefeIntro,
                    x: 1150,
                    duration: 2400,
                    ease: 'Linear',
                    onComplete: () => {
                        raptores.destroy();
                        palermitanoJefeIntro.destroy();
                    }
                });
            });
        });
    });

    escena.time.delayedCall(9500, () => {
        cajaTexto.destroy();
        textoNarrado.destroy();
        mesa.destroy();

        jugador.setPosition(80, CARRIL_SUPERIOR_Y);
        carrilActual = CARRIL_SUPERIOR_Y;
        estaSaltando = false;
        jugador.setVisible(true);
        enCinematica = false;
        mostrarMensaje(escena, '¡SALVA LA RECETA TRADICIONAL!\nPERSEVERA POR LA RUTA 38');
    });
}

// =============================================================================
// SISTEMA DE INSOLACIÓN ACELERADA
// =============================================================================
function actualizarSistemaInsolacion(escena, time) {
    if (jugador.x > 5000) {
        if (!insolacionActiva) {
            insolacionActiva = true;
            solSprite.setAlpha(1);
            mostrarMensaje(escena, '¡EL SOL DE LA SIESTA APRIETA!\nBusca Achilatas para no insolarte');
        }

        let progreso = Math.min(1, (jugador.x - 5000) / 7500);
        solSprite.setScale(0.40 + (progreso * 0.70));
        capaTinteCalor.setAlpha(progreso * 0.22);

        // Nota para mí: Subo el incremento a 0.075 para que la insolación sea una amenaza palpable
        nivelInsolacion = Math.min(100, nivelInsolacion + 0.075);
        dibujarBarraInsolacion();

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

function recolectarAchilata(jugadorRef, achilata) {
    if (Math.abs(carrilActual - achilata.y) > 25) return;
    achilata.destroy();
    nivelInsolacion = Math.max(0, nivelInsolacion - 50);
    puntos += 100;
    dibujarBarraInsolacion();
    actualizarHUD();
    mostrarMensaje(jugadorRef.scene, '¡QUÉ RICA ACHILATA!\nInsolación reducida');
}

// =============================================================================
// VEHÍCULOS (BUSES GRANDES Y AUTOS EN RUTA)
// =============================================================================
function lanzarColectivo(escena, x, spriteKey, velocidad) {
    let carrilY = (Math.random() > 0.5) ? CARRIL_SUPERIOR_Y + 15 : CARRIL_INFERIOR_Y + 10;
    let bus = colectivos.create(x, carrilY, spriteKey);
    bus.setOrigin(0.5, 1);
    // Nota para mí: Escala subida a 2.15 para tamaño real imponente
    bus.setScale(2.15);
    bus.setDepth(carrilY);
    bus.vida = 10;
    bus.velocidadX = velocidad;
    bus.averiado = false;
    bus.setImmovable(true);
    bus.body.allowGravity = false;

    let anchoReal = bus.displayWidth * 0.85;
    let altoReal = bus.displayHeight * 0.88;
    bus.body.setSize(anchoReal, altoReal);
    bus.body.setOffset((bus.displayWidth - anchoReal) / 2, bus.displayHeight - altoReal);

    escena.tweens.add({
        targets: bus, y: carrilY - 2, duration: 180, yoyo: true, repeat: -1, ease: 'Sine.easeInOut'
    });
}

function crearAutoEnRuta(escena, x, carrilY, spriteKey, velX) {
    let auto = autosRuta.create(x, carrilY + 8, spriteKey);
    auto.setOrigin(0.5, 1);
    auto.setScale(1.15);
    auto.setDepth(carrilY);
    auto.vida = 4;
    auto.velocidadX = velX;
    auto.averiado = false;
    auto.setImmovable(true);
    auto.body.allowGravity = false;

    let ancho = auto.displayWidth * 0.80;
    let alto = auto.displayHeight * 0.80;
    auto.body.setSize(ancho, alto);
    auto.body.setOffset((auto.displayWidth - ancho) / 2, auto.displayHeight - alto);
}

function actualizarColectivos() {
    colectivos.children.iterate((bus) => {
        if (!bus || !bus.active) return;
        bus.setVelocityX(!bus.averiado ? bus.velocidadX : 0);
    });
}

function actualizarAutosRuta() {
    autosRuta.children.iterate((auto) => {
        if (!auto || !auto.active) return;
        auto.setVelocityX(!auto.averiado ? auto.velocidadX : 0);
    });
}

function manejarColisionVehiculo(jugadorRef, vehiculo) {
    if (jugadorRef.y < vehiculo.body.top) return;
    if (Math.abs(carrilActual - vehiculo.y) > 35) return;

    if (!vehiculo.averiado) {
        recibirDanioJugador(jugadorRef.scene);
    }
}

function impactarVehiculo(proyectil, vehiculo) {
    if (!vehiculo || !vehiculo.active || vehiculo.averiado) return;
    if (Math.abs(proyectil.y - (vehiculo.y - vehiculo.displayHeight / 2)) > 70) return;

    let danio = (armaActual === 'CASCOTE') ? 3 : 1;
    vehiculo.vida -= danio;
    proyectil.destroy();
    vehiculo.setTint(0xff2222);

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
// OLEADAS Y SPAWN DE ENEMIGOS
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
            id: 1, triggerX: 900, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', -65);
                spawnEnemigo(escena, 'HIPSTER', 0);
                spawnEnemigo(escena, 'HIPSTER', 500);
            }
        },
        {
            id: 2, triggerX: 2500, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', -60);
                spawnEnemigo(escena, 'AGENTE', 0);
                spawnEnemigo(escena, 'HIPSTER', 600);
            }
        },
        {
            id: 3, triggerX: 4500, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', -65);
                spawnEnemigo(escena, 'AGENTE', 0);
                spawnEnemigo(escena, 'GRANDOTE', 600);
            }
        },
        {
            id: 4, triggerX: 7000, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'tesa', -60);
                spawnEnemigo(escena, 'GRANDOTE', 0);
                spawnEnemigo(escena, 'AGENTE', 500);
            }
        },
        {
            id: 5, triggerX: 9500, ejecutar: () => {
                lanzarColectivo(escena, escena.cameras.main.scrollX + ANCHO_VISTA + 80, 'exprebus', -65);
                spawnEnemigo(escena, 'GRANDOTE', 0);
                spawnEnemigo(escena, 'AGENTE', 600);
                spawnEnemigo(escena, 'HIPSTER', 1100);
            }
        },
        {
            id: 6, triggerX: 12000, ejecutar: () => {
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
// COMPORTAMIENTOS E IA: DETENCIÓN PARA DISPARAR Y PUÑETAZOS
// =============================================================================
function actualizarIAHipsters(escena) {
    hipsters.children.iterate((hipster) => {
        if (!hipster || !hipster.active) return;
        if (hipster.estaDisparando) return;

        let dist = Math.abs(hipster.x - jugador.x);

        // Nota para mí: Si entra en rango de disparo, se frena completamente para arrojar la botella
        if (dist < 650 && escena.time.now > hipster.ultimoAtaque + 2400 && Math.abs(carrilActual - hipster.y) < 40) {
            hipster.estaDisparando = true;
            hipster.setVelocityX(0);
            hipster.anims.play('hipster_lanzar', true);

            escena.time.delayedCall(300, () => {
                if (hipster && hipster.active) {
                    let botella = proyectilesEnemigos.create(hipster.x - 16, hipster.y - 6, 'botella_agua');
                    botella.setScale(0.14);
                    botella.setDepth(hipster.y + (hipster.displayHeight * 0.5));
                    botella.setVelocity(-270, 0);
                    botella.velocidadGiro = -16;
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

        hipster.setVelocityX(-65);
        hipster.anims.play('hipster_run', true);
    });
}

function actualizarIAAgentes(escena) {
    agentes.children.iterate((agente) => {
        if (!agente || !agente.active) return;
        if (agente.estaDisparando) return;

        let dist = Math.abs(agente.x - jugador.x);

        // Nota para mí: El agente frena en seco para apuntar y disparar con retroceso
        if (dist < 700 && escena.time.now > agente.ultimoDisparo + 2000 && Math.abs(carrilActual - agente.y) < 40) {
            agente.estaDisparando = true;
            agente.setVelocityX(0);
            agente.anims.play('agente_disparar', true);

            escena.time.delayedCall(250, () => {
                if (agente && agente.active) {
                    let bala = proyectilesEnemigos.create(agente.x - 20, agente.y - 6, 'bala');
                    bala.setScale(0.20);
                    bala.setDepth(agente.y + (agente.displayHeight * 0.5));
                    bala.setVelocity(-340, 0);
                }
            });

            escena.time.delayedCall(600, () => {
                if (agente && agente.active) {
                    agente.ultimoDisparo = escena.time.now;
                    agente.estaDisparando = false;
                }
            });
            return;
        }

        if (dist > 180) {
            agente.setVelocityX(-75);
            agente.anims.play('agente_run', true);
        } else {
            agente.setVelocityX(0);
        }
    });
}

function actualizarIAGrandotes(escena) {
    grandotes.children.iterate((grandote) => {
        if (!grandote || !grandote.active) return;
        if (grandote.atacandoCuerpoACuerpo) return;

        let dist = Math.abs(grandote.x - jugador.x);

        // Nota para mí: Activación estricta de la animación de puñetazo al acercarse al Ciruja
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

        grandote.setVelocityX(-100);
        grandote.anims.play('grandote_run', true);
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
// SALUD (SIN IMPULSOS VERTICALES)
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
        jugador.setVelocityX(jugador.flipX ? 160 : -160);

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