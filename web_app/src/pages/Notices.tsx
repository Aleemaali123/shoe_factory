import { useTitle } from '../components/ui'
import { useShop } from '../data/shop'

export function NoticesPage() {
  useTitle('Notifications')
  const shop = useShop()

  return (
    <section>
      <div className="section-head">
        <h2>Notifications</h2>
        {shop.unread ? (
          <button className="text-btn" type="button" onClick={() => void shop.markAllNotices()}>
            Mark all read
          </button>
        ) : null}
      </div>
      {shop.notices.length ? (
        <div className="orders">
          {shop.notices.map((notice) => (
            <article key={notice.id} className="notice" style={{ opacity: notice.read ? 0.72 : 1 }}>
              <strong>{notice.title}</strong>
              <p>{notice.body}</p>
              <p className="muted">{notice.timeLabel}</p>
              <div className="actions">
                {!notice.read ? (
                  <button className="text-btn" type="button" onClick={() => void shop.markNotice(notice.id)}>
                    Mark read
                  </button>
                ) : null}
                <button className="text-btn" type="button" onClick={() => void shop.dismissNotice(notice.id)}>
                  Dismiss
                </button>
              </div>
            </article>
          ))}
        </div>
      ) : (
        <div className="panel empty">
          <h2>You are all caught up</h2>
          <p className="muted">Order updates and shop notices will land here.</p>
        </div>
      )}
    </section>
  )
}
