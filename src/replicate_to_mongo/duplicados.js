db.pf_pessoas.aggregate([
  { $group: { _id: "$cpf", count: { $sum: 1 } } },
  { $match: { count: { $gt: 1 } } },
  { $lookup: {
      from: "pf_pessoas",
      localField: "_id",
      foreignField: "cpf",
      as: "duplicados"
  }},
  { $unwind: "$duplicados" },
  { $replaceRoot: { newRoot: "$duplicados" } },
  { $project: { nome: 1, cpf: 1, _id: 0 } }
])

