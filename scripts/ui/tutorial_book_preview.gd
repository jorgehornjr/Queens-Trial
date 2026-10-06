extends Control
## Execute esta cena com F6 para folhear os seis capítulos sem jogar a campanha.

var book: TutorialBook
var next_chapter := 1


func _ready() -> void:
	book = TutorialBook.new()
	add_child(book)
	book.unlock_to(6)
	book.dismissed.connect(_advance)
	book.present(next_chapter, true)


func _advance() -> void:
	next_chapter = next_chapter % 6 + 1
	await get_tree().create_timer(0.7).timeout
	book.present(next_chapter, true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			next_chapter = int(event.keycode - KEY_1 + 1)
			book.present(next_chapter, true)
