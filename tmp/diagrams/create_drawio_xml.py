from pathlib import Path
import xml.etree.ElementTree as ET


OUTPUT = Path("output/xml")
OUTPUT.mkdir(parents=True, exist_ok=True)

COLORS = {
    "background": "#FCF7F1",
    "surface": "#FFFDF9",
    "header": "#FFE3C2",
    "border": "#B75217",
    "text": "#3C1B14",
    "muted": "#80675D",
    "relation": "#73351E",
}

POSITIONS = {
    "profile": (40, 245, 230, 160),
    "work": (40, 30, 230, 135),
    "note": (40, 485, 230, 145),
    "health": (370, 30, 260, 170),
    "goal": (370, 245, 260, 155),
    "checkin": (750, 250, 245, 140),
    "plan": (370, 485, 260, 155),
    "task": (750, 485, 245, 170),
}

CONCEPTUAL = {
    "profile": ("ELORA_PROFILE", [
        ("PK", "profile_id"), ("UK", "firebase_uid"),
        ("*", "display_name"), ("*", "created_at"), ("*", "updated_at"),
    ]),
    "work": ("ELORA_WORK_CONTEXT", [
        ("PK", "context_id"), ("FK", "profile_id"),
        ("*", "context_code"), ("*", "updated_at"),
    ]),
    "note": ("ELORA_CONSULTATION_NOTE", [
        ("PK", "note_id"), ("FK", "profile_id"), ("*", "note_text"),
        ("*", "created_at"), ("*", "updated_at"),
    ]),
    "health": ("ELORA_HEALTH_RECORD", [
        ("PK", "record_id"), ("FK", "profile_id"),
        ("*", "indicator_code"), ("*", "value_number"),
        ("*", "recorded_at"), ("*", "source_code"), ("*", "created_at"),
    ]),
    "goal": ("ELORA_CARE_GOAL", [
        ("PK", "goal_id"), ("FK", "profile_id"), ("*", "title"),
        ("*", "active"), ("*", "created_at"), ("*", "updated_at"),
    ]),
    "checkin": ("ELORA_GOAL_CHECKIN", [
        ("PK", "checkin_id"), ("FK/UK", "goal_id"),
        ("UK", "completed_on"), ("*", "created_at"),
    ]),
    "plan": ("ELORA_PROTECTION_PLAN", [
        ("PK", "plan_id"), ("FK", "profile_id"), ("*", "risk_code"),
        ("*", "title"), ("*", "created_at"), ("*", "updated_at"),
    ]),
    "task": ("ELORA_PLAN_TASK", [
        ("PK", "task_id"), ("FK", "plan_id"), ("*", "title"),
        ("*", "position_number"), ("o", "completed_at"),
        ("*", "created_at"), ("*", "updated_at"),
    ]),
}

PHYSICAL = {
    "profile": ("ELORA_PROFILE", [
        ("PK", "profile_id", "NUMBER"), ("UK", "firebase_uid", "VARCHAR2(128)"),
        ("", "display_name", "VARCHAR2(80)"), ("", "created_at", "TIMESTAMPTZ"),
        ("", "updated_at", "TIMESTAMPTZ"),
    ]),
    "work": ("ELORA_WORK_CONTEXT", [
        ("PK", "context_id", "NUMBER"), ("FK/UK", "profile_id", "NUMBER"),
        ("", "context_code", "VARCHAR2(20)"), ("", "updated_at", "TIMESTAMPTZ"),
    ]),
    "note": ("ELORA_CONSULTATION_NOTE", [
        ("PK", "note_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "note_text", "CLOB"), ("", "created_at", "TIMESTAMPTZ"),
        ("", "updated_at", "TIMESTAMPTZ"),
    ]),
    "health": ("ELORA_HEALTH_RECORD", [
        ("PK", "record_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "indicator_code", "VARCHAR2(20)"), ("", "value_number", "NUMBER(10,2)"),
        ("", "recorded_at", "TIMESTAMPTZ"), ("", "source_code", "VARCHAR2(20)"),
        ("", "created_at", "TIMESTAMPTZ"),
    ]),
    "goal": ("ELORA_CARE_GOAL", [
        ("PK", "goal_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "title", "VARCHAR2(120)"), ("", "active", "CHAR(1)"),
        ("", "created_at", "TIMESTAMPTZ"), ("", "updated_at", "TIMESTAMPTZ"),
    ]),
    "checkin": ("ELORA_GOAL_CHECKIN", [
        ("PK", "checkin_id", "NUMBER"), ("FK/UK", "goal_id", "NUMBER"),
        ("UK", "completed_on", "DATE"), ("", "created_at", "TIMESTAMPTZ"),
    ]),
    "plan": ("ELORA_PROTECTION_PLAN", [
        ("PK", "plan_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "risk_code", "VARCHAR2(20)"), ("", "title", "VARCHAR2(120)"),
        ("", "created_at", "TIMESTAMPTZ"), ("", "updated_at", "TIMESTAMPTZ"),
    ]),
    "task": ("ELORA_PLAN_TASK", [
        ("PK", "task_id", "NUMBER"), ("FK", "plan_id", "NUMBER"),
        ("", "title", "VARCHAR2(120)"), ("", "position_number", "NUMBER(5)"),
        ("", "completed_at", "TIMESTAMPTZ"), ("", "created_at", "TIMESTAMPTZ"),
        ("", "updated_at", "TIMESTAMPTZ"),
    ]),
}

RELATIONSHIPS = [
    ("profile", "work", "1 : 0..1"),
    ("profile", "note", "1 : 0..N"),
    ("profile", "health", "1 : 0..N"),
    ("profile", "goal", "1 : 0..N"),
    ("goal", "checkin", "1 : 0..N"),
    ("profile", "plan", "1 : 0..N"),
    ("plan", "task", "1 : 0..N"),
]


def label_for(title, rows, physical):
    body = []
    for row in rows:
        if physical:
            key, name, data_type = row
            key_html = f'<b><font color="#B75217">{key}</font></b>' if key else "&nbsp;"
            body.append(
                f'<tr><td width="42">{key_html}</td><td><b>{name}</b></td>'
                f'<td align="right"><font color="#80675D">{data_type}</font></td></tr>'
            )
        else:
            key, name = row
            key_html = f'<b><font color="#B75217">{key}</font></b>' if key else "&nbsp;"
            body.append(f'<tr><td width="48">{key_html}</td><td>{name}</td></tr>')
    return (
        f'<div style="font-size:13px;color:#3C1B14"><b>{title}</b></div>'
        '<hr style="border:none;border-top:1px solid #B75217">'
        f'<table width="100%" cellpadding="2" cellspacing="0" style="font-size:10px">{"".join(body)}</table>'
    )


def build_diagram(name, data, physical):
    mxfile = ET.Element("mxfile", {
        "host": "app.diagrams.net",
        "modified": "2026-11-15T21:30:00.000Z",
        "agent": "Codex",
        "version": "26.0.9",
        "type": "device",
        "compressed": "false",
    })
    diagram = ET.SubElement(mxfile, "diagram", {"id": f"elora-{name.lower()}", "name": name})
    model = ET.SubElement(diagram, "mxGraphModel", {
        "dx": "1300", "dy": "850", "grid": "1", "gridSize": "10",
        "guides": "1", "tooltips": "1", "connect": "1", "arrows": "1",
        "fold": "1", "page": "1", "pageScale": "1",
        "pageWidth": "1169", "pageHeight": "827", "math": "0", "shadow": "0",
        "background": COLORS["background"],
    })
    root = ET.SubElement(model, "root")
    ET.SubElement(root, "mxCell", {"id": "0"})
    ET.SubElement(root, "mxCell", {"id": "1", "parent": "0"})

    title = ET.SubElement(root, "mxCell", {
        "id": "title", "value": f"{name} - ELORA",
        "style": (
            "text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;"
            "whiteSpace=wrap;rounded=0;fontSize=28;fontStyle=1;fontColor=#3C1B14;"
        ),
        "vertex": "1", "parent": "1",
    })
    ET.SubElement(title, "mxGeometry", {"x": "40", "y": "-40", "width": "500", "height": "50", "as": "geometry"})

    subtitle_text = (
        "Modelo lógico/físico com tipos Oracle, chaves e restrições"
        if physical else "Visão conceitual com entidades, atributos e cardinalidades"
    )
    subtitle = ET.SubElement(root, "mxCell", {
        "id": "subtitle", "value": subtitle_text,
        "style": "text;html=1;strokeColor=none;fillColor=none;align=left;fontSize=13;fontColor=#80675D;",
        "vertex": "1", "parent": "1",
    })
    ET.SubElement(subtitle, "mxGeometry", {"x": "40", "y": "4", "width": "560", "height": "25", "as": "geometry"})

    for key, (title_text, rows) in data.items():
        x, y, width, height = POSITIONS[key]
        cell = ET.SubElement(root, "mxCell", {
            "id": key,
            "value": label_for(title_text, rows, physical),
            "style": (
                "rounded=1;whiteSpace=wrap;html=1;arcSize=8;align=left;verticalAlign=top;"
                "spacing=10;fillColor=#FFFDF9;strokeColor=#B75217;strokeWidth=2;"
                "fontColor=#3C1B14;shadow=0;"
            ),
            "vertex": "1", "parent": "1",
        })
        ET.SubElement(cell, "mxGeometry", {
            "x": str(x), "y": str(y), "width": str(width), "height": str(height), "as": "geometry",
        })

    for index, (source, target, cardinality) in enumerate(RELATIONSHIPS, start=1):
        end_arrow = "ERzeroToOne" if cardinality.endswith("0..1") else "ERzeroToMany"
        edge = ET.SubElement(root, "mxCell", {
            "id": f"rel{index}", "value": cardinality,
            "style": (
                "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;"
                "dashed=1;dashPattern=6 4;strokeColor=#73351E;strokeWidth=2;"
                f"startArrow=ERone;startFill=0;endArrow={end_arrow};endFill=0;"
                "fontSize=11;fontStyle=1;fontColor=#73351E;labelBackgroundColor=#FCF7F1;"
            ),
            "edge": "1", "parent": "1", "source": source, "target": target,
        })
        ET.SubElement(edge, "mxGeometry", {"relative": "1", "as": "geometry"})

    legend_value = (
        "<b>LEGENDA</b><br><br>PK - chave primária<br>FK - chave estrangeira<br>"
        "UK - chave ou conjunto único<br>1 / 0..1 / 0..N - cardinalidade"
    )
    legend = ET.SubElement(root, "mxCell", {
        "id": "legend", "value": legend_value,
        "style": (
            "rounded=1;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacing=12;"
            "fillColor=#F9EDE2;strokeColor=#D9BBA8;fontColor=#3C1B14;fontSize=11;"
        ),
        "vertex": "1", "parent": "1",
    })
    ET.SubElement(legend, "mxGeometry", {"x": "750", "y": "30", "width": "245", "height": "140", "as": "geometry"})

    ET.indent(mxfile, space="  ")
    return ET.ElementTree(mxfile)


for filename, name, data, physical in [
    ("ELORA-DER.xml", "DER", CONCEPTUAL, False),
    ("ELORA-MER.xml", "MER", PHYSICAL, True),
]:
    destination = OUTPUT / filename
    build_diagram(name, data, physical).write(destination, encoding="utf-8", xml_declaration=True)
    print(destination.resolve())
