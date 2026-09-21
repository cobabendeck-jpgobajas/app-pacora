from typing import Optional
from pydantic import BaseModel, Field


class PrediccionOut(BaseModel):
    id: int
    dosis_predicha_mg_l: float
    jarra_recomendada: int = Field(
        description="Numero de jarra del protocolo de laboratorio (solucion madre 10 000 mg/L, "
                    "N mL por cada 100 mL de jarra) equivalente a la dosis predicha: "
                    "jarra = dosis_predicha_mg_l / 100, redondeado al entero mas cercano. "
                    "El operario usa este numero -junto con el caudal real de la planta en el "
                    "momento- para calcular manualmente la cantidad de producto a dosificar; "
                    "el proyecto automatiza la prueba de jarras (45 min), no ese calculo final.",
    )
    turbiedad_estimada_unt: Optional[float] = Field(
        default=None,
        description="Turbiedad estimada por el modelo (UNT), dato complementario a la dosis. "
                    "Puede ser null si el modelo de turbiedad no esta disponible en el servidor.",
    )
    modelo: str
    features: dict
    filename: str


class PrediccionDB(BaseModel):
    id: int
    creado_en: str
    filename: str
    image_path: str
    dosis_predicha_mg_l: float
    turbiedad_estimada_unt: Optional[float] = None
    modelo: str
    dosis_real_mg_l: Optional[float] = None
    turbiedad_real_unt: Optional[float] = None
    verificado_en: Optional[str] = None


class VerificacionIn(BaseModel):
    dosis_real_mg_l: Optional[float] = Field(
        default=None, description="Dosis realmente aplicada en planta (mg/L), si se conoce")
    turbiedad_real_unt: Optional[float] = Field(
        default=None, description="Turbiedad medida con turbidimetro (UNT/NTU), si se conoce")


class HealthOut(BaseModel):
    status: str
    modelo: str
    caracteristicas_esperadas: list
