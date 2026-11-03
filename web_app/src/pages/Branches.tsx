import { useTitle } from '../components/ui'
import { useShop } from '../data/shop'

export function BranchesPage() {
  useTitle('Branches')
  const shop = useShop()

  return (
    <section>
      <div className="section-head">
        <div>
          <h2>Branches</h2>
          <p className="muted">Pickup orders use the branch you select.</p>
        </div>
      </div>
      <div className="grid">
        {shop.branches.map((branch) => {
          const selected = branch.id === shop.branchId
          return (
            <article key={branch.id} className={selected ? 'panel address on' : 'panel'}>
              <h3>{branch.name}</h3>
              <p>{branch.address}</p>
              <p className="muted">{branch.hours}</p>
              <p>{branch.phone}</p>
              <button className={selected ? 'btn primary' : 'btn line'} type="button" onClick={() => shop.setBranch(branch.id)} style={{ marginTop: 12 }}>
                {selected ? 'Shopping this branch' : 'Shop this branch'}
              </button>
            </article>
          )
        })}
      </div>
    </section>
  )
}
