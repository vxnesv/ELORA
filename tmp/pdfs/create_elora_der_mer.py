from pathlib import Path

from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas


OUTPUT = Path("output/pdf/ELORA-DER-MER.pdf")
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

PAGE_W, PAGE_H = landscape(A4)
BG = HexColor("#FCF7F1")
SURFACE = HexColor("#FFFDF9")
SURFACE_ALT = HexColor("#F9EDE2")
TEXT = HexColor("#3C1B14")
MUTED = HexColor("#80675D")
ACCENT = HexColor("#B75217")
ACCENT_SOFT = HexColor("#FFE3C2")
BORDER = HexColor("#D9BBA8")
RELATION = HexColor("#73351E")
PK = HexColor("#B75217")
FK = HexColor("#2B6F6A")
UK = HexColor("#6A4C93")


def rounded_box(c, x, y, w, h, title, rows, physical=False):
    c.setFillColor(SURFACE)
    c.setStrokeColor(ACCENT)
    c.setLineWidth(1.2)
    c.roundRect(x, y, w, h, 8, fill=1, stroke=1)

    header_h = 24
    c.setFillColor(ACCENT_SOFT)
    c.roundRect(x, y + h - header_h, w, header_h, 8, fill=1, stroke=0)
    c.rect(x, y + h - header_h, w, 8, fill=1, stroke=0)
    c.setStrokeColor(ACCENT)
    c.line(x, y + h - header_h, x + w, y + h - header_h)
    c.setFillColor(TEXT)
    c.setFont("Helvetica-Bold", 8.2 if physical else 9.2)
    c.drawCentredString(x + w / 2, y + h - 16, title)

    font_size = 5.5 if physical else 7.1
    line_h = 9.0 if physical else 11.2
    row_y = y + h - header_h - line_h + 1
    for row in rows:
        if physical:
            key, name, data_type = row
            key_color = PK if "PK" in key else FK if "FK" in key else UK
            c.setFillColor(key_color if key else MUTED)
            c.setFont("Helvetica-Bold", font_size)
            c.drawString(x + 7, row_y, key)
            c.setFillColor(TEXT)
            c.setFont("Helvetica", font_size)
            c.drawString(x + 31, row_y, name)
            type_w = stringWidth(data_type, "Helvetica", font_size)
            c.setFillColor(MUTED)
            c.drawString(x + w - type_w - 7, row_y, data_type)
        else:
            key, name, required = row
            c.setFillColor(PK if key == "PK" else FK if key == "FK" else MUTED)
            c.setFont("Helvetica-Bold", font_size)
            c.drawString(x + 8, row_y, key or ("*" if required else "o"))
            c.setFillColor(TEXT)
            c.setFont("Helvetica", font_size)
            c.drawString(x + 38, row_y, name)
        row_y -= line_h


def relationship(c, start, end, start_card, end_card, via=None):
    points = [start] + (via or []) + [end]
    c.setStrokeColor(RELATION)
    c.setLineWidth(1.15)
    c.setDash(5, 3)
    path = c.beginPath()
    path.moveTo(*points[0])
    for point in points[1:]:
        path.lineTo(*point)
    c.drawPath(path, stroke=1, fill=0)
    c.setDash()

    c.setFillColor(RELATION)
    c.setFont("Helvetica-Bold", 7)
    c.drawString(start[0] + 4, start[1] + 4, start_card)
    end_label_w = stringWidth(end_card, "Helvetica-Bold", 7)
    c.drawString(end[0] - end_label_w - 4, end[1] + 4, end_card)


def page_header(c, acronym, title, subtitle, page_number):
    c.setFillColor(BG)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillColor(ACCENT)
    c.roundRect(32, PAGE_H - 66, 58, 30, 8, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 14)
    c.drawCentredString(61, PAGE_H - 56, acronym)
    c.setFillColor(TEXT)
    c.setFont("Helvetica-Bold", 20)
    c.drawString(104, PAGE_H - 48, title)
    c.setFillColor(MUTED)
    c.setFont("Helvetica", 8.5)
    c.drawString(104, PAGE_H - 62, subtitle)
    c.setStrokeColor(BORDER)
    c.line(32, 34, PAGE_W - 32, 34)
    c.setFillColor(MUTED)
    c.setFont("Helvetica", 7.5)
    c.drawString(32, 21, "ELORA - Inteligencia preventiva para a vida real")
    c.drawRightString(PAGE_W - 32, 21, f"MVP 1.0  |  pagina {page_number}/2")


def draw_der(c):
    page_header(
        c,
        "DER",
        "Diagrama Entidade-Relacionamento",
        "Visao conceitual: entidades, atributos essenciais e cardinalidades.",
        1,
    )

    entities = {
        "PROFILE": (34, 236, 180, 128),
        "WORK": (34, 409, 180, 100),
        "NOTE": (34, 70, 180, 108),
        "HEALTH": (322, 407, 210, 112),
        "GOAL": (322, 240, 210, 108),
        "CHECKIN": (620, 246, 185, 96),
        "PLAN": (322, 70, 210, 112),
        "TASK": (620, 70, 185, 112),
    }

    rounded_box(c, *entities["PROFILE"], "ELORA_PROFILE", [
        ("PK", "profile_id", True), ("UK", "firebase_uid", True),
        ("", "display_name", True), ("", "created_at", True),
        ("", "updated_at", True),
    ])
    rounded_box(c, *entities["WORK"], "ELORA_WORK_CONTEXT", [
        ("PK", "context_id", True), ("FK", "profile_id", True),
        ("", "context_code", True), ("", "updated_at", True),
    ])
    rounded_box(c, *entities["NOTE"], "ELORA_CONSULTATION_NOTE", [
        ("PK", "note_id", True), ("FK", "profile_id", True),
        ("", "note_text", True), ("", "created_at", True),
        ("", "updated_at", True),
    ])
    rounded_box(c, *entities["HEALTH"], "ELORA_HEALTH_RECORD", [
        ("PK", "record_id", True), ("FK", "profile_id", True),
        ("", "indicator_code", True), ("", "value_number", True),
        ("", "recorded_at", True), ("", "source_code", True),
    ])
    rounded_box(c, *entities["GOAL"], "ELORA_CARE_GOAL", [
        ("PK", "goal_id", True), ("FK", "profile_id", True),
        ("", "title", True), ("", "active", True),
        ("", "created_at", True),
    ])
    rounded_box(c, *entities["CHECKIN"], "ELORA_GOAL_CHECKIN", [
        ("PK", "checkin_id", True), ("FK/UK", "goal_id", True),
        ("UK", "completed_on", True), ("", "created_at", True),
    ])
    rounded_box(c, *entities["PLAN"], "ELORA_PROTECTION_PLAN", [
        ("PK", "plan_id", True), ("FK", "profile_id", True),
        ("", "risk_code", True), ("", "title", True),
        ("", "created_at", True),
    ])
    rounded_box(c, *entities["TASK"], "ELORA_PLAN_TASK", [
        ("PK", "task_id", True), ("FK", "plan_id", True),
        ("", "title", True), ("", "position_number", True),
        ("", "completed_at", False),
    ])

    relationship(c, (124, 364), (124, 409), "1", "0..1")
    relationship(c, (124, 236), (124, 178), "1", "0..N")
    relationship(c, (214, 324), (322, 463), "1", "0..N", [(268, 324), (268, 463)])
    relationship(c, (214, 300), (322, 294), "1", "0..N")
    relationship(c, (214, 262), (322, 126), "1", "0..N", [(274, 262), (274, 126)])
    relationship(c, (532, 294), (620, 294), "1", "0..N")
    relationship(c, (532, 126), (620, 126), "1", "0..N")

    c.setFillColor(SURFACE_ALT)
    c.roundRect(620, 400, 185, 102, 8, fill=1, stroke=0)
    c.setFillColor(TEXT)
    c.setFont("Helvetica-Bold", 8)
    c.drawString(632, 482, "LEGENDA")
    c.setFont("Helvetica", 7)
    c.drawString(632, 465, "PK  chave primaria")
    c.drawString(632, 451, "FK  chave estrangeira")
    c.drawString(632, 437, "UK  valor ou conjunto unico")
    c.drawString(632, 423, "* obrigatorio   o opcional")
    c.drawString(632, 409, "1 / 0..N / 1..N  cardinalidade")


def draw_mer(c):
    page_header(
        c,
        "MER",
        "Modelo Entidade-Relacionamento",
        "Visao logica/fisica: tabelas Oracle, tipos de dados, chaves e restricoes.",
        2,
    )

    entities = {
        "PROFILE": (30, 232, 218, 142),
        "WORK": (30, 413, 218, 100),
        "NOTE": (30, 62, 218, 120),
        "HEALTH": (312, 400, 245, 126),
        "GOAL": (312, 230, 245, 120),
        "CHECKIN": (618, 238, 195, 104),
        "PLAN": (312, 62, 245, 120),
        "TASK": (618, 62, 195, 126),
    }

    rounded_box(c, *entities["PROFILE"], "ELORA_PROFILE", [
        ("PK", "profile_id", "NUMBER"), ("UK", "firebase_uid", "VARCHAR2(128)"),
        ("", "display_name", "VARCHAR2(80)"), ("", "created_at", "TIMESTAMPTZ"),
        ("", "updated_at", "TIMESTAMPTZ"),
    ], True)
    rounded_box(c, *entities["WORK"], "ELORA_WORK_CONTEXT", [
        ("PK", "context_id", "NUMBER"), ("FK/UK", "profile_id", "NUMBER"),
        ("", "context_code", "VARCHAR2(20)"), ("", "updated_at", "TIMESTAMPTZ"),
    ], True)
    rounded_box(c, *entities["NOTE"], "ELORA_CONSULTATION_NOTE", [
        ("PK", "note_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "note_text", "CLOB"), ("", "created_at", "TIMESTAMPTZ"),
        ("", "updated_at", "TIMESTAMPTZ"),
    ], True)
    rounded_box(c, *entities["HEALTH"], "ELORA_HEALTH_RECORD", [
        ("PK", "record_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "indicator_code", "VARCHAR2(20)"), ("", "value_number", "NUMBER(10,2)"),
        ("", "recorded_at", "TIMESTAMPTZ"), ("", "source_code", "VARCHAR2(20)"),
        ("", "created_at", "TIMESTAMPTZ"),
    ], True)
    rounded_box(c, *entities["GOAL"], "ELORA_CARE_GOAL", [
        ("PK", "goal_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "title", "VARCHAR2(120)"), ("", "active", "CHAR(1)"),
        ("", "created_at", "TIMESTAMPTZ"), ("", "updated_at", "TIMESTAMPTZ"),
    ], True)
    rounded_box(c, *entities["CHECKIN"], "ELORA_GOAL_CHECKIN", [
        ("PK", "checkin_id", "NUMBER"), ("FK/UK", "goal_id", "NUMBER"),
        ("UK", "completed_on", "DATE"), ("", "created_at", "TIMESTAMPTZ"),
    ], True)
    rounded_box(c, *entities["PLAN"], "ELORA_PROTECTION_PLAN", [
        ("PK", "plan_id", "NUMBER"), ("FK", "profile_id", "NUMBER"),
        ("", "risk_code", "VARCHAR2(20)"), ("", "title", "VARCHAR2(120)"),
        ("", "created_at", "TIMESTAMPTZ"), ("", "updated_at", "TIMESTAMPTZ"),
    ], True)
    rounded_box(c, *entities["TASK"], "ELORA_PLAN_TASK", [
        ("PK", "task_id", "NUMBER"), ("FK", "plan_id", "NUMBER"),
        ("", "title", "VARCHAR2(120)"), ("", "position_number", "NUMBER(5)"),
        ("", "completed_at", "TIMESTAMPTZ"), ("", "created_at", "TIMESTAMPTZ"),
        ("", "updated_at", "TIMESTAMPTZ"),
    ], True)

    relationship(c, (139, 374), (139, 413), "1", "0..1")
    relationship(c, (139, 232), (139, 182), "1", "0..N")
    relationship(c, (248, 330), (312, 463), "1", "0..N", [(278, 330), (278, 463)])
    relationship(c, (248, 291), (312, 290), "1", "0..N")
    relationship(c, (248, 255), (312, 122), "1", "0..N", [(280, 255), (280, 122)])
    relationship(c, (557, 290), (618, 290), "1", "0..N")
    relationship(c, (557, 122), (618, 122), "1", "0..N")

    c.setFillColor(SURFACE_ALT)
    c.roundRect(618, 405, 195, 104, 8, fill=1, stroke=0)
    c.setFillColor(TEXT)
    c.setFont("Helvetica-Bold", 8)
    c.drawString(630, 490, "RESTRICOES PRINCIPAIS")
    c.setFont("Helvetica", 6.5)
    for index, line in enumerate([
        "firebase_uid unico por perfil",
        "check-in unico por meta e dia",
        "um contexto atual por perfil",
        "codigos controlados por CHECK",
        "dependencias com ON DELETE CASCADE",
    ]):
        c.drawString(630, 474 - index * 13, line)


pdf = canvas.Canvas(str(OUTPUT), pagesize=(PAGE_W, PAGE_H))
pdf.setTitle("ELORA - DER e MER")
pdf.setAuthor("Equipe ELORA")
pdf.setSubject("Modelagem de dados do MVP ELORA")
draw_der(pdf)
pdf.showPage()
draw_mer(pdf)
pdf.showPage()
pdf.save()

print(OUTPUT.resolve())
