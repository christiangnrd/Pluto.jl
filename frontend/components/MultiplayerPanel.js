import _ from "../imports/lodash.js"
import { html, useEffect, useRef, useContext, useState, useLayoutEffect, useCallback } from "../imports/Preact.js"
import { PerfectCursor } from "../imports/PerfectCursors.js"
import { PlutoActionsContext } from "../common/PlutoContext.js"

// TODO: investigate why effect is bad with low throttle rate?
// ....  update notebook should be pretty fast.
const CURSOR_THROTTLE_RATE = 80
const DEFAULT_CURSOR_COLOR = "#eeeeee"

const mouse_data_to_point = ({relative_to_cell, relative_x, relative_y}) => {
    const cell_elt = document.getElementById(relative_to_cell)

    if (cell_elt === null) {
        // Cell might not be synced
        return [relative_x, relative_y]
    }

    return [
        relative_x + cell_elt.offsetLeft,
        relative_y + cell_elt.offsetTop,
    ]
}

// l² norm in pixel space
const dist2 = (x1, y1, x2, y2) => (x1 - x2) ^ 2 + (y1 - y2) ^ 2

const update_mouse_data = (mouseX, mouseY) => {
    const cell_nodes = Array.from(document.querySelectorAll("pluto-notebook > pluto-cell"))

    let best_index = null
    let best_dist = Infinity
    let relative_x = mouseX
    let relative_y = mouseY

    const mousePt = [mouseX, mouseY]

    for (let { id: cell_id, offsetLeft: cell_x, offsetTop: cell_y } of cell_nodes) {
        const dist_with_cell = dist2(mouseX, mouseY, cell_x, cell_y)
        if (dist_with_cell < best_dist) {
            best_dist = dist_with_cell
            best_index = cell_id
            relative_x = mouseX - cell_x
            relative_y = mouseY - cell_y
        }
    }

    return { relative_to_cell: best_index, relative_x, relative_y }
}

// https://github.com/steveruizok/perfect-cursors/tree/main?tab=readme-ov-file#usage-in-react
const usePerfectCursor = (cb, point) => {
    const [pc] = useState(() => new PerfectCursor(cb))

    useLayoutEffect(() => {
        if (point) pc.addPoint(point)
        return () => pc.dispose()
    }, [pc])

    const onPointChange = useCallback(
        (point) => pc.addPoint(point),
     [pc])

    return onPointChange
}

// hex needs to be a string of length 7 example: '#bedbad'
const hexToRGBA = (hex, alpha) => `rgba(${parseInt(hex.slice(1,3),16)},${parseInt(hex.slice(3,5),16)},${parseInt(hex.slice(5,8),16)},${alpha})`

const Cursor = ({ mouse: point, color }) => {
    if (!point) return
    const r = useRef(null)

    const animate = useCallback((point) => {
        const elm = r.current
        if (!elm) return
        elm.style.setProperty("transform", `translate(${point[0]}px, ${point[1]}px)`)
    }, [])

    const onPointMove = usePerfectCursor(animate)
    useLayoutEffect(() => onPointMove(point), [point, onPointMove])

    color = color ?? DEFAULT_CURSOR_COLOR

    return html`
    <svg
      ref=${r}
      version="1.1"
      viewBox="0 0 8.2089 8.2089"
      xmlns="http://www.w3.org/2000/svg"
      style=${{
        position: "absolute",
        top: -6,
        left: -6,
        width: 20,
        height: 20,
        filter: `drop-shadow(2px 2px 2px ${hexToRGBA(color, 0.6)})`,
      }}>
     <g transform="translate(-66.531 -43.399)">
        <path
            fill=${color}
            d="m66.531 43.399 2.6474 8.2089s0.84672-2.7549 1.8267-3.7348 3.7348-1.8267 3.7348-1.8267z" />
     </g>
    </svg>`
}

const usePassiveDocumentEventListener = (event_name, handler_fn, deps) => {
    useEffect(() => {
        document.addEventListener(event_name, handler_fn, { passive: true })
        return () => document.removeEventListener(event_name, handler_fn)
    }, deps)
}

const useMousePositionWithScroll = () => {
  const [{pageX, pageY, scrollX, scrollY}, setState] = useState({})

  usePassiveDocumentEventListener("mousemove", ({pageX,pageY}) => {
      setState({ 
          pageX,
          pageY,
          scrollX: window.scrollX,
          scrollY: window.scrollY,
      })
  }, [])

    usePassiveDocumentEventListener("scrollend", () => {
        const { scrollX: newScrollX, scrollY: newScrollY } = window
        const dX = newScrollX - scrollX
        const dY = newScrollY - scrollY
        setState({
            pageX: pageX + dX,
            pageY: pageY + dY,
            scrollX: newScrollX,
            scrollY: newScrollY,
        })
    }, [pageX, pageY, scrollX, scrollY])

    return { pageX, pageY }
}

const MyCursorSyncer = ({ client_id }) => {
    const { update_notebook } = useContext(PlutoActionsContext)

    const update_mouse_position = useCallback(_.throttle((event) => {
        update_notebook(notebook => {
            if (!(client_id in notebook.users)) return
            notebook.users[client_id].mouse = update_mouse_data(event.pageX, event.pageY)
        })
    }, CURSOR_THROTTLE_RATE), [client_id, update_notebook])

    const mouseData = useMousePositionWithScroll()
    useEffect(
        () => update_mouse_position(mouseData),
        [mouseData, update_mouse_position],
    )

    const hide_mouse_for_client = useCallback(() => update_notebook(notebook => {
        if (!(client_id in notebook.users)) return
        notebook.users[client_id].mouse = null
    }), [client_id])

    usePassiveDocumentEventListener("blur", hide_mouse_for_client, [hide_mouse_for_client])

    return null
}

export const MultiplayerPanel = ({ users, client_id }) => {
    if (!users || !Object.keys(users).some(user_id => user_id != client_id)) return

    return html`
        <${MyCursorSyncer} client_id=${client_id} />
        <pluto-cursor-list>
        ${Object.entries(users).map(
            ([clientID, { name, mouse, color, focused_cell }]) =>
                    client_id == clientID || !mouse ? null : html`<${Cursor} key=${clientID} mouse=${mouse_data_to_point(mouse)} color=${color} />`
        )}
        </pluto-cursor-list>
    `
}
