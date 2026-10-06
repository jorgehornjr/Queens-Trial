extends RefCounted
## Texto vivo das páginas aprovadas; nenhuma regra de gameplay é modificada aqui.

const ROMANS := [
	"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
	"XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX",
]

const CHAPTERS := {
	1: {
		"title": "O primeiro\nédito",
		"body": "Vire a carta e guarde o número.\n\nQuando ela desaparecer, ande essa quantidade de casas.",
		"art": "color_first_edict",
	},
	2: {
		"title": "Dois éditos",
		"body": "Vire as duas cartas e guarde os números.\n\nCumpra os éditos em ordem: primeiro o da esquerda, depois o da direita.\n\nPlaneje a rota para cumprir os dois e terminar na casa iluminada do tabuleiro.",
		"art": "color_two_edicts",
	},
	3: {
		"title": "As torres",
		"body": "Depois dos seus passos, as torres avançam.\n\nO número acima de cada torre indica quantas casas ela anda. A quantidade é a mesma na linha e na coluna.\n\nElas atacam em linha reta. Observe onde vão chegar e evite terminar no alcance delas.",
		"art": "color_rooks",
	},
	4: {
		"title": "A ordem\ndos pares",
		"body": "As quatro torres atacam em pares.\n\nAs flechas junto às peças indicam o par que vai agir neste édito.\n\nNo próximo édito, será a vez do outro par.\n\nObserve a ordem dos ataques antes de escolher o caminho.",
		"art": "color_attack_order",
	},
	5: {
		"title": "Os bispos",
		"body": "Os bispos atacam pelas diagonais.\n\nO ataque segue casas da mesma cor, em caminhos inclinados que se cruzam como um X.\n\nDepois dos seus passos, eles avançam. Observe onde vão chegar e evite terminar em uma dessas diagonais.",
		"art": "color_bishops",
	},
	6: {
		"title": "A balança",
		"body": "Agora, os números das cartas são pesos.\n\nObserve as cartas e os pratos da balança. Você tem cinco segundos para se mover antes de o tabuleiro se inclinar.\n\nPode andar livremente. Não há uma casa iluminada nesta prova.\n\nQual lado pesa mais? Para onde o tabuleiro pode inclinar?",
		"art": "color_balance",
	},
}


static func chapter(number: int) -> Dictionary:
	return CHAPTERS.get(number, {})
